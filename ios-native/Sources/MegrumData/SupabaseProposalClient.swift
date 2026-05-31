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
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
        return rows.compactMap(\.proposal)
    }

    public func createProposal(senderID: UUID, input: ProposalCreateInput) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.upsertRows(
            into: "proposals",
            values: [ProposalCreatePayload(senderID: senderID, input: input)],
            select: ProposalRow.select
        )
        return rows.first?.proposal ?? TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: input.receiverID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags,
            agreedBySender: input.status == .sent || input.status == .agreementOneSide || input.status == .agreed,
            agreedByReceiver: input.status == .agreed
        )
    }

    public func agreeProposal(userID: UUID, proposalID: UUID, acceptedExchangeMethod: ExchangeMethod?) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.canRespondToProposal else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let resolvedExchangeMethod = try proposal.resolvedExchangeMethod(forAcceptance: acceptedExchangeMethod)
        let nextAgreement = proposal.nextAgreementApproved(by: userID)
        let status: ProposalStatus = nextAgreement.agreedBySender && nextAgreement.agreedByReceiver
            ? .agreed
            : .agreementOneSide
        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalAgreementUpdatePayload(
                agreedBySender: nextAgreement.agreedBySender,
                agreedByReceiver: nextAgreement.agreedByReceiver,
                status: status.rawValue,
                exchangeMethod: resolvedExchangeMethod == proposal.exchangeMethod ? nil : resolvedExchangeMethod.rawValue
            ),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: status == .agreed ? "打診が成立しました" : "打診に合意しました"
        )
        return updated
    }

    public func rejectProposal(userID: UUID, proposalID: UUID) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.canRespondToProposal else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalStatusUpdatePayload(status: ProposalStatus.rejected.rawValue),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: "打診を断りました"
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

        let contentType = normalizedImageContentType(input.imageContentType)
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
        let now = isoTimestamp(.now)
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

    public func approveEvidence(userID: UUID, proposalID: UUID) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        if proposal.status == .completed {
            return proposal
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        guard proposal.evidencePhotoURL != nil else {
            throw SupabaseProposalClientError.missingEvidence
        }

        let approvedBySender = proposal.isSender(userID) ? true : proposal.approvedBySender
        let approvedByReceiver = proposal.isSender(userID) ? proposal.approvedByReceiver : true
        let bothApproved = approvedBySender && approvedByReceiver
        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalApprovalUpdatePayload(
                approvedBySender: approvedBySender,
                approvedByReceiver: approvedByReceiver,
                status: bothApproved ? ProposalStatus.completed.rawValue : nil,
                completedAt: bothApproved ? isoTimestamp(.now) : nil
            ),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: bothApproved ? "両者が承認しました。取引完了" : "証跡を承認しました"
        )
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
                    comment: input.comment?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
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
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
    }

    public func makeCreateProposalRequest(senderID: UUID, input: ProposalCreateInput) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ],
            method: "POST",
            body: encoder.encode([ProposalCreatePayload(senderID: senderID, input: input)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    public func makeAgreeProposalRequest(
        userID: UUID,
        proposal: TradeProposal,
        acceptedExchangeMethod: ExchangeMethod? = nil
    ) throws -> URLRequest {
        let resolvedExchangeMethod = try proposal.resolvedExchangeMethod(forAcceptance: acceptedExchangeMethod)
        let nextAgreement = proposal.nextAgreementApproved(by: userID)
        let status: ProposalStatus = nextAgreement.agreedBySender && nextAgreement.agreedByReceiver
            ? .agreed
            : .agreementOneSide
        return try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "id", value: "eq.\(proposal.id.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ],
            method: "PATCH",
            body: encoder.encode(
                ProposalAgreementUpdatePayload(
                    agreedBySender: nextAgreement.agreedBySender,
                    agreedByReceiver: nextAgreement.agreedByReceiver,
                    status: status.rawValue,
                    exchangeMethod: resolvedExchangeMethod == proposal.exchangeMethod ? nil : resolvedExchangeMethod.rawValue
                )
            ),
            prefer: "return=representation"
        )
    }

    public func makeRejectProposalRequest(proposalID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ],
            method: "PATCH",
            body: encoder.encode(ProposalStatusUpdatePayload(status: ProposalStatus.rejected.rawValue)),
            prefer: "return=representation"
        )
    }

    public func makeApproveEvidenceRequest(userID: UUID, proposal: TradeProposal) throws -> URLRequest {
        let approvedBySender = proposal.isSender(userID) ? true : proposal.approvedBySender
        let approvedByReceiver = proposal.isSender(userID) ? proposal.approvedByReceiver : true
        let bothApproved = approvedBySender && approvedByReceiver
        return try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "id", value: "eq.\(proposal.id.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ],
            method: "PATCH",
            body: encoder.encode(
                ProposalApprovalUpdatePayload(
                    approvedBySender: approvedBySender,
                    approvedByReceiver: approvedByReceiver,
                    status: bothApproved ? ProposalStatus.completed.rawValue : nil,
                    completedAt: bothApproved ? isoTimestamp(.now) : nil
                )
            ),
            prefer: "return=representation"
        )
    }

    public func makeSubmitEvaluationRequest(userID: UUID, proposal: TradeProposal, input: TradeEvaluationCreateInput) throws -> URLRequest {
        let rateeID = proposal.partnerID(for: userID) ?? proposal.receiverID
        return try client.makeInsertRequest(
            into: "user_evaluations",
            values: [
                EvaluationInsertPayload(
                    proposalID: input.proposalID,
                    raterID: userID,
                    rateeID: rateeID,
                    stars: input.stars,
                    comment: input.comment?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
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

    private func evidencePhotoPath(proposalID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(proposalID.uuidString.lowercased())/evidence-\(milliseconds)-\(UUID().uuidString.lowercased()).\(fileExtension(for: contentType))"
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
        "status",
        "exchange_method",
        "sender_have_ids",
        "receiver_have_ids",
        "option_tags",
        "agreed_by_sender",
        "agreed_by_receiver",
        "evidence_photo_url",
        "evidence_taken_at",
        "evidence_taken_by",
        "approved_by_sender",
        "approved_by_receiver",
        "completed_at",
        "created_at"
    ].joined(separator: ",")

    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var status: String
    var exchangeMethod: String?
    var senderHaveIds: [UUID]?
    var receiverHaveIds: [UUID]?
    var optionTags: [String]?
    var agreedBySender: Bool?
    var agreedByReceiver: Bool?
    var evidencePhotoUrl: String?
    var evidenceTakenAt: Date?
    var evidenceTakenBy: UUID?
    var approvedBySender: Bool?
    var approvedByReceiver: Bool?
    var completedAt: Date?
    var createdAt: Date?

    var proposal: TradeProposal? {
        guard let proposalStatus = ProposalStatus(rawValue: status) else {
            return nil
        }
        return TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            status: proposalStatus,
            exchangeMethod: ExchangeMethod(rawValue: exchangeMethod ?? "hand") ?? .hand,
            senderGoodsIDs: senderHaveIds ?? [],
            receiverGoodsIDs: receiverHaveIds ?? [],
            conditionTags: optionTags ?? [],
            agreedBySender: agreedBySender ?? false,
            agreedByReceiver: agreedByReceiver ?? false,
            evidencePhotoURL: evidencePhotoUrl.flatMap(URL.init(string:)),
            evidenceTakenAt: evidenceTakenAt,
            evidenceTakenBy: evidenceTakenBy,
            approvedBySender: approvedBySender ?? false,
            approvedByReceiver: approvedByReceiver ?? false,
            completedAt: completedAt,
            createdAt: createdAt ?? .now
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
    var status: String
    var exchangeMethod: String
    var optionTags: [String]
    var exposeCalendar: Bool
    var listingId: UUID?
    var agreedBySender: Bool

    init(senderID: UUID, input: ProposalCreateInput) {
        self.senderId = senderID
        self.receiverId = input.receiverID
        self.matchType = input.matchType.rawValue
        self.senderHaveIds = input.senderGoodsIDs
        self.senderHaveQtys = input.senderGoodsIDs.map { _ in 1 }
        self.receiverHaveIds = input.receiverGoodsIDs
        self.receiverHaveQtys = input.receiverGoodsIDs.map { _ in 1 }
        self.message = input.message?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.status = input.status.rawValue
        self.exchangeMethod = input.exchangeMethod.rawValue
        self.optionTags = input.conditionTags
        self.exposeCalendar = false
        self.listingId = input.listingID
        self.agreedBySender = input.status == .sent || input.status == .agreed || input.status == .agreementOneSide
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private func isoTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

private func normalizedImageContentType(_ value: String) -> String {
    switch value.lowercased() {
    case "image/png":
        "image/png"
    case "image/webp":
        "image/webp"
    default:
        "image/jpeg"
    }
}

private func fileExtension(for contentType: String) -> String {
    switch normalizedImageContentType(contentType) {
    case "image/png":
        "png"
    case "image/webp":
        "webp"
    default:
        "jpg"
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
