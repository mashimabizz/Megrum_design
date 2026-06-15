import Foundation
import MegrumCore

public enum SupabaseProposalClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case proposalNotFound
    case notParticipant
    case invalidStatus
    case missingEvidence
    case malformedResponse
    case invalidRating
    case missingMeetup
}

public final class SupabaseProposalClient: @unchecked Sendable {
    private static let chatPhotoBucket = "chat-photos"
    private static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadProposals(viewerID: UUID) async throws -> [TradeProposal] {
        let viewer = viewerID.uuidString.lowercased()
        let rows: [ProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: ProposalRow.select,
            queryItems: [
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "updated_at.desc.nullslast,created_at.desc")
            ]
        )
        return rows.compactMap(\.proposal)
    }

    public func createProposal(senderID: UUID, input: ProposalCreateInput, now: Date = .now) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.upsertRows(
            into: "proposals",
            values: [try ProposalCreatePayload(senderID: senderID, input: input, now: now)],
            select: ProposalRow.select
        )
        return rows.first?.proposal ?? TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: input.receiverID,
            listingID: input.listingID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags,
            cashOffer: input.cashOffer,
            cashAmount: input.cashAmount,
            agreedBySender: [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status),
            agreedByReceiver: input.status == .agreed,
            createdAt: now,
            updatedAt: now
        )
    }

    public func agreeProposal(userID: UUID, proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.rpcRows(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposalID,
                action: "agree",
                acceptedExchangeMethod: acceptedExchangeMethod?.rawValue
            )
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: updated.status == .agreed ? "打診が成立しました" : "打診に合意しました"
        )
        return updated
    }

    public func rejectProposal(userID: UUID, proposalID: UUID) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.rpcRows(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposalID,
                action: "reject",
                acceptedExchangeMethod: nil
            )
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: updated.senderID == userID ? "打診を取り下げました" : "打診を断りました"
        )
        return updated
    }

    public func addEvidencePhoto(userID: UUID, input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        guard input.imageData.count <= Self.maxUploadBytes else {
            throw SupabaseProposalClientError.imageTooLarge
        }

        let proposal = try await loadProposal(proposalID: input.proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let contentType = SupabaseImageContentTypeNormalizer.lenient(input.imageContentType)
        let path = evidencePhotoPath(proposalID: input.proposalID, contentType: contentType)
        try await client.uploadObject(
            bucket: Self.chatPhotoBucket,
            path: path,
            data: input.imageData,
            contentType: contentType,
            upsert: false
        )
        let signedURL = try await client.createSignedURL(
            bucket: Self.chatPhotoBucket,
            path: path,
            expiresIn: 60 * 60 * 24 * 365
        )

        let nextPosition = try await nextEvidencePhotoPosition(proposalID: input.proposalID)
        let now = SupabaseDateEncoding.isoTimestamp(.now)
        let _: [EvidencePhotoAckRow] = try await client.insertRows(
            into: "proposal_evidence_photos",
            values: [
                EvidencePhotoInsertPayload(
                    proposalID: input.proposalID,
                    photoURL: signedURL.absoluteString,
                    position: nextPosition,
                    takenAt: now,
                    takenBy: userID
                )
            ],
            select: "id"
        )

        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalEvidenceUpdatePayload(
                evidencePhotoURL: proposal.evidencePhotoURL == nil ? signedURL.absoluteString : nil,
                evidenceTakenAt: now,
                evidenceTakenBy: userID
            ),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: input.proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: "取引証跡が追加されました"
        )
        return updated
    }

    public func loadEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        let rows: [EvidencePhotoRow] = try await client.fetchRows(
            from: "proposal_evidence_photos",
            select: EvidencePhotoRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.asc")
            ]
        )
        return rows.compactMap(\.evidencePhoto)
    }

    public func approveEvidence(userID: UUID, proposalID: UUID) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.rpcRows(
            function: "approve_trade_evidence_for_viewer",
            payload: ProposalApprovalRPCPayload(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: updated.status == .completed ? "両者が承認しました。取引完了" : "証跡を承認しました"
        )
        return updated
    }

    public func approveCancel(userID: UUID, proposalID: UUID, now: Date = .now) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalCancelApprovalUpdatePayload(now: now),
            select: ProposalRow.select,
            queryItems: cancelApprovalQueryItems(proposalID: proposalID, userID: userID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.invalidStatus
        }
        return updated
    }

    public func submitEvaluation(userID: UUID, input: TradeEvaluationCreateInput) async throws -> UserEvaluation {
        guard (1...5).contains(input.stars) else {
            throw SupabaseProposalClientError.invalidRating
        }
        let proposal = try await loadProposal(proposalID: input.proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .completed, let rateeID = proposal.partnerID(for: userID) else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let rows: [EvaluationInsertRow] = try await client.insertRows(
            into: "user_evaluations",
            values: [
                EvaluationInsertPayload(
                    proposalID: input.proposalID,
                    raterID: userID,
                    rateeID: rateeID,
                    stars: input.stars,
                    comment: SupabaseTextNormalizer.optional(input.comment)
                )
            ],
            select: "id,rater_id,stars,comment,created_at"
        )
        guard let evaluation = rows.first?.evaluation else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: "取引評価を送信しました"
        )
        return evaluation
    }

    public func makeLoadProposalsRequest(viewerID: UUID) throws -> URLRequest {
        let viewer = viewerID.uuidString.lowercased()
        return try client.makeRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "updated_at.desc.nullslast,created_at.desc")
            ]
        )
    }

    public func makeLoadEvidencePhotosRequest(proposalID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/proposal_evidence_photos",
            queryItems: [
                URLQueryItem(name: "select", value: EvidencePhotoRow.select),
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.asc")
            ]
        )
    }

    public func makeCreateProposalRequest(senderID: UUID, input: ProposalCreateInput, now: Date = .now) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ],
            method: "POST",
            body: encoder.encode([try ProposalCreatePayload(senderID: senderID, input: input, now: now)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    public func makeAgreeProposalRequest(
        userID: UUID,
        proposal: TradeProposal,
        acceptedExchangeMethod: ExchangeMethod? = nil
    ) throws -> URLRequest {
        _ = userID
        let resolvedExchangeMethod = try proposal.resolvedExchangeMethod(forAcceptance: acceptedExchangeMethod)
        return try client.makeRPCRequest(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposal.id,
                action: "agree",
                acceptedExchangeMethod: resolvedExchangeMethod == proposal.exchangeMethod ? nil : resolvedExchangeMethod.rawValue
            )
        )
    }

    public func makeRejectProposalRequest(proposalID: UUID) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposalID,
                action: "reject",
                acceptedExchangeMethod: nil
            )
        )
    }

    public func makeApproveEvidenceRequest(userID: UUID, proposal: TradeProposal) throws -> URLRequest {
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed || proposal.status == .completed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        guard proposal.evidencePhotoURL != nil else {
            throw SupabaseProposalClientError.missingEvidence
        }
        return try client.makeRPCRequest(
            function: "approve_trade_evidence_for_viewer",
            payload: ProposalApprovalRPCPayload(proposalID: proposal.id)
        )
    }

    public func makeApproveCancelRequest(userID: UUID, proposal: TradeProposal, now: Date = .now) throws -> URLRequest {
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        return try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ] + cancelApprovalQueryItems(proposalID: proposal.id, userID: userID),
            method: "PATCH",
            body: encoder.encode(ProposalCancelApprovalUpdatePayload(now: now)),
            prefer: "return=representation"
        )
    }

    public func makeSubmitEvaluationRequest(userID: UUID, proposal: TradeProposal, input: TradeEvaluationCreateInput) throws -> URLRequest {
        guard (1...5).contains(input.stars) else {
            throw SupabaseProposalClientError.invalidRating
        }
        guard proposal.isParticipant(userID), let rateeID = proposal.partnerID(for: userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .completed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        return try client.makeInsertRequest(
            into: "user_evaluations",
            values: [
                EvaluationInsertPayload(
                    proposalID: input.proposalID,
                    raterID: userID,
                    rateeID: rateeID,
                    stars: input.stars,
                    comment: SupabaseTextNormalizer.optional(input.comment)
                )
            ],
            select: "id,rater_id,stars,comment,created_at"
        )
    }

    private func loadProposal(proposalID: UUID) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let proposal = rows.first?.proposal else {
            throw SupabaseProposalClientError.proposalNotFound
        }
        return proposal
    }

    private func nextEvidencePhotoPosition(proposalID: UUID) async throws -> Int {
        let rows: [EvidencePhotoPositionRow] = try await client.fetchRows(
            from: "proposal_evidence_photos",
            select: "position",
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return (rows.first?.position ?? 0) + 1
    }

    private func createSystemMessage(proposalID: UUID, senderID: UUID, body: String) async throws {
        let _: [SystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [SystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body)],
            select: "id"
        )
    }

    private func proposalQueryItems(proposalID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func cancelApprovalQueryItems(proposalID: UUID, userID: UUID) -> [URLQueryItem] {
        let viewer = userID.uuidString.lowercased()
        return [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(ProposalStatus.agreed.rawValue)"),
            URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func evidencePhotoPath(proposalID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(proposalID.uuidString.lowercased())/evidence-\(milliseconds)-\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct ProposalRow: Decodable, Sendable {
    static let select = [
        "id",
        "sender_id",
        "receiver_id",
        "listing_id",
        "status",
        "exchange_method",
        "sender_have_ids",
        "receiver_have_ids",
        "cash_offer",
        "cash_amount",
        "option_tags",
        "agreed_by_sender",
        "agreed_by_receiver",
        "evidence_photo_url",
        "evidence_taken_at",
        "evidence_taken_by",
        "approved_by_sender",
        "approved_by_receiver",
        "completed_at",
        "meetup_start_at",
        "meetup_end_at",
        "meetup_place_name",
        "meetup_lat",
        "meetup_lng",
        "meetup_candidates",
        "created_at",
        "updated_at"
    ].joined(separator: ",")

    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var listingId: UUID?
    var status: String
    var exchangeMethod: String?
    var senderHaveIds: [UUID]?
    var receiverHaveIds: [UUID]?
    var cashOffer: Bool?
    var cashAmount: Int?
    var optionTags: [String]?
    var agreedBySender: Bool?
    var agreedByReceiver: Bool?
    var evidencePhotoUrl: String?
    var evidenceTakenAt: Date?
    var evidenceTakenBy: UUID?
    var approvedBySender: Bool?
    var approvedByReceiver: Bool?
    var completedAt: Date?
    var meetupStartAt: Date?
    var meetupEndAt: Date?
    var meetupPlaceName: String?
    var meetupLat: Double?
    var meetupLng: Double?
    var meetupCandidates: [ProposalMeetupCandidateRow]?
    var createdAt: Date?
    var updatedAt: Date?

    var proposal: TradeProposal? {
        guard let proposalStatus = ProposalStatus(rawValue: status) else {
            return nil
        }
        return TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            listingID: listingId,
            status: proposalStatus,
            exchangeMethod: ExchangeMethod(rawValue: exchangeMethod ?? "hand") ?? .hand,
            senderGoodsIDs: senderHaveIds ?? [],
            receiverGoodsIDs: receiverHaveIds ?? [],
            conditionTags: optionTags ?? [],
            cashOffer: cashOffer ?? false,
            cashAmount: cashAmount,
            agreedBySender: agreedBySender ?? false,
            agreedByReceiver: agreedByReceiver ?? false,
            evidencePhotoURL: evidencePhotoUrl.flatMap(URL.init(string:)),
            evidenceTakenAt: evidenceTakenAt,
            evidenceTakenBy: evidenceTakenBy,
            approvedBySender: approvedBySender ?? false,
            approvedByReceiver: approvedByReceiver ?? false,
            completedAt: completedAt,
            createdAt: createdAt ?? .now,
            updatedAt: updatedAt,
            meetupCandidates: normalizedMeetupCandidates
        )
    }

    private var mirroredMeetup: ProposalMeetupInput? {
        guard let meetupStartAt,
              let meetupEndAt,
              let placeName = SupabaseTextNormalizer.optional(meetupPlaceName),
              let meetupLat,
              let meetupLng
        else {
            return nil
        }
        let meetup = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: placeName,
            latitude: meetupLat,
            longitude: meetupLng
        )
        return meetup.isValid ? meetup : nil
    }

    private var normalizedMeetupCandidates: [ProposalMeetupInput]? {
        var candidates = meetupCandidates?
            .map(\.meetupInput)
            .filter(\.isValid) ?? []
        if let mirroredMeetup {
            candidates.removeAll { $0.isSameMeetup(as: mirroredMeetup) }
            candidates.insert(mirroredMeetup, at: 0)
        }
        return candidates.isEmpty ? nil : Array(candidates.prefix(3))
    }
}

private struct ProposalMeetupCandidateRow: Decodable, Sendable {
    var startAt: Date
    var endAt: Date
    var placeName: String
    var lat: Double
    var lng: Double

    var meetupInput: ProposalMeetupInput {
        ProposalMeetupInput(
            startAt: startAt,
            endAt: endAt,
            placeName: placeName,
            latitude: lat,
            longitude: lng
        )
    }
}

private struct ProposalCreatePayload: Encodable, Sendable {
    var senderId: UUID
    var receiverId: UUID
    var matchType: String
    var senderHaveIds: [UUID]
    var senderHaveQtys: [Int]
    var receiverHaveIds: [UUID]
    var receiverHaveQtys: [Int]
    var message: String?
    var messageTone: String
    var status: String
    var lastActionAt: String
    var expiresAt: String?
    var exchangeMethod: String
    var optionTags: [String]
    var exposeCalendar: Bool
    var listingId: UUID?
    var cashOffer: Bool
    var cashAmount: Int?
    var meetupStartAt: String?
    var meetupEndAt: String?
    var meetupPlaceName: String?
    var meetupLat: Double?
    var meetupLng: Double?
    var meetupCandidates: [ProposalMeetupCandidatePayload]
    var agreedBySender: Bool

    init(senderID: UUID, input: ProposalCreateInput, now: Date) throws {
        let meetupCandidates = Self.normalizedMeetupCandidates(for: input)
        let meetup = meetupCandidates.first
        if input.requiresMeetupBeforeSending {
            guard meetup?.isValid == true else {
                throw SupabaseProposalClientError.missingMeetup
            }
        }
        let expiresAt = Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: now)
        self.senderId = senderID
        self.receiverId = input.receiverID
        self.matchType = input.matchType.rawValue
        self.senderHaveIds = input.senderGoodsIDs
        self.senderHaveQtys = input.senderGoodsIDs.map { _ in 1 }
        self.receiverHaveIds = input.receiverGoodsIDs
        self.receiverHaveQtys = input.receiverGoodsIDs.map { _ in 1 }
        self.message = SupabaseTextNormalizer.optional(input.message)
        self.messageTone = "standard"
        self.status = input.status.rawValue
        self.lastActionAt = SupabaseDateEncoding.isoTimestamp(now)
        self.expiresAt = input.status == .draft ? nil : expiresAt.map(SupabaseDateEncoding.isoTimestamp)
        self.exchangeMethod = input.exchangeMethod.rawValue
        self.optionTags = input.conditionTags
        self.exposeCalendar = input.requiresMeetupBeforeSending && input.exposeCalendar
        self.listingId = input.listingID
        self.cashOffer = input.cashOffer
        self.cashAmount = input.cashAmount
        self.meetupStartAt = meetup.map { SupabaseDateEncoding.isoTimestamp($0.startAt) }
        self.meetupEndAt = meetup.map { SupabaseDateEncoding.isoTimestamp($0.endAt) }
        self.meetupPlaceName = SupabaseTextNormalizer.optional(meetup?.normalizedPlaceName)
        self.meetupLat = meetup?.latitude
        self.meetupLng = meetup?.longitude
        self.meetupCandidates = meetupCandidates.map(ProposalMeetupCandidatePayload.init)
        self.agreedBySender = [.sent, .negotiating, .agreementOneSide, .agreed].contains(input.status)
    }

    private static func normalizedMeetupCandidates(for input: ProposalCreateInput) -> [ProposalMeetupInput] {
        var candidates = input.meetupCandidates.filter(\.isValid)
        if let meetup = input.meetup, meetup.isValid {
            candidates.removeAll { $0.isSameMeetup(as: meetup) }
            candidates.insert(meetup, at: 0)
        }
        return Array(candidates.prefix(3))
    }
}

private struct ProposalMeetupCandidatePayload: Encodable, Sendable {
    var startAt: String
    var endAt: String
    var placeName: String
    var lat: Double
    var lng: Double
    var mode: String

    init(meetup: ProposalMeetupInput) {
        self.startAt = SupabaseDateEncoding.isoTimestamp(meetup.startAt)
        self.endAt = SupabaseDateEncoding.isoTimestamp(meetup.endAt)
        self.placeName = meetup.normalizedPlaceName
        self.lat = meetup.latitude
        self.lng = meetup.longitude
        self.mode = "scheduled"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([
            "startAt": ProposalMeetupCandidateValue.string(startAt),
            "endAt": .string(endAt),
            "placeName": .string(placeName),
            "lat": .double(lat),
            "lng": .double(lng),
            "mode": .string(mode)
        ])
    }
}

private enum ProposalMeetupCandidateValue: Encodable, Sendable {
    case string(String)
    case double(Double)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }
}

private extension ProposalMeetupInput {
    func isSameMeetup(as other: ProposalMeetupInput) -> Bool {
        startAt == other.startAt
            && endAt == other.endAt
            && normalizedPlaceName == other.normalizedPlaceName
            && latitude == other.latitude
            && longitude == other.longitude
    }
}

private struct ProposalResponseRPCPayload: Encodable, Sendable {
    var pProposalID: UUID
    var pAction: String
    var pAcceptedExchangeMethod: String?

    init(proposalID: UUID, action: String, acceptedExchangeMethod: String?) {
        self.pProposalID = proposalID
        self.pAction = action
        self.pAcceptedExchangeMethod = acceptedExchangeMethod
    }
}

private struct ProposalApprovalRPCPayload: Encodable, Sendable {
    var pProposalID: UUID

    init(proposalID: UUID) {
        self.pProposalID = proposalID
    }
}

private struct ProposalAgreementUpdatePayload: Encodable, Sendable {
    var agreedBySender: Bool
    var agreedByReceiver: Bool
    var status: String
    var exchangeMethod: String?
}

private struct ProposalStatusUpdatePayload: Encodable, Sendable {
    var status: String
}

private struct ProposalEvidenceUpdatePayload: Encodable, Sendable {
    var evidencePhotoURL: String?
    var evidenceTakenAt: String
    var evidenceTakenBy: UUID
}

private struct ProposalApprovalUpdatePayload: Encodable, Sendable {
    var approvedBySender: Bool
    var approvedByReceiver: Bool
    var status: String?
    var completedAt: String?
}

private struct ProposalCancelApprovalUpdatePayload: Encodable, Sendable {
    var status = ProposalStatus.cancelled.rawValue
    var lastActionAt: String

    init(now: Date) {
        self.lastActionAt = SupabaseDateEncoding.isoTimestamp(now)
    }
}

private struct EvidencePhotoInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var photoURL: String
    var position: Int
    var takenAt: String
    var takenBy: UUID
}

private struct EvidencePhotoAckRow: Decodable, Sendable {
    var id: UUID
}

private struct EvidencePhotoPositionRow: Decodable, Sendable {
    var position: Int?
}

private struct EvidencePhotoRow: Decodable, Sendable {
    static let select = "id,proposal_id,photo_url,position,taken_at,taken_by"

    var id: UUID
    var proposalId: UUID
    var photoUrl: String
    var position: Int?
    var takenAt: Date?
    var takenBy: UUID

    var evidencePhoto: TradeEvidencePhoto? {
        guard let url = URL(string: photoUrl) else {
            return nil
        }
        return TradeEvidencePhoto(
            id: id,
            proposalID: proposalId,
            photoURL: url,
            position: position ?? 1,
            takenAt: takenAt,
            takenBy: takenBy
        )
    }
}

private struct SystemMessagePayload: Encodable, Sendable {
    var proposalID: UUID
    var senderID: UUID
    var messageType = TradeMessageType.system.rawValue
    var body: String
}

private struct SystemMessageAckRow: Decodable, Sendable {
    var id: UUID
}

private struct EvaluationInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var raterID: UUID
    var rateeID: UUID
    var stars: Int
    var comment: String?
}

private struct EvaluationInsertRow: Decodable, Sendable {
    var id: UUID
    var raterId: UUID
    var stars: Int
    var comment: String?
    var createdAt: Date?

    var evaluation: UserEvaluation {
        UserEvaluation(
            id: id,
            raterID: raterId,
            raterHandle: "me",
            raterDisplayName: "自分",
            stars: stars,
            comment: comment,
            createdAt: createdAt ?? .now
        )
    }
}

private extension TradeProposal {
    var canRespondToProposal: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }

    func resolvedExchangeMethod(forAcceptance selectedMethod: ExchangeMethod?) throws -> ExchangeMethod {
        switch exchangeMethod {
        case .both:
            guard let selectedMethod, selectedMethod != .both else {
                throw SupabaseProposalClientError.invalidStatus
            }
            return selectedMethod
        case .hand, .mail:
            if let selectedMethod, selectedMethod != exchangeMethod {
                throw SupabaseProposalClientError.invalidStatus
            }
            return exchangeMethod
        }
    }

    func nextAgreementApproved(by userID: UUID) -> (agreedBySender: Bool, agreedByReceiver: Bool) {
        let senderIsImplicitlyAgreed = status == .sent
        let nextSender = isSender(userID) ? true : (agreedBySender || senderIsImplicitlyAgreed)
        let nextReceiver = isSender(userID) ? agreedByReceiver : true
        return (nextSender, nextReceiver)
    }
}
