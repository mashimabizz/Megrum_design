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

private enum SupabaseProposalSystemAction: String, Sendable {
    case evidenceAdded = "evidence_added"
}

public final class SupabaseProposalClient: @unchecked Sendable {
    private static let chatPhotoBucket = "chat-photos"
    private static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
    let client: SupabaseRESTClient
    let encoder: JSONEncoder

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
            cashAmountSide: input.cashAmountSide,
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
            body: "取引証跡が追加されました",
            meta: ["action": SupabaseProposalSystemAction.evidenceAdded.rawValue]
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

    public func deleteEvidencePhoto(userID: UUID, proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let photos = try await loadEvidencePhotos(proposalID: proposalID)
        guard let target = photos.first(where: { $0.id == photoID }) else {
            throw SupabaseProposalClientError.malformedResponse
        }
        guard target.takenBy == userID else {
            throw SupabaseProposalClientError.notParticipant
        }

        try await client.deleteRows(
            from: "proposal_evidence_photos",
            queryItems: evidencePhotoDeleteQueryItems(userID: userID, proposalID: proposalID, photoID: photoID)
        )

        let remainingPhotos = photos
            .filter { $0.id != photoID }
            .sorted { $0.position < $1.position }
        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalEvidenceReplacementPayload(photo: remainingPhotos.first),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        return updated
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

    private func createSystemMessage(
        proposalID: UUID,
        senderID: UUID,
        body: String,
        meta: [String: String] = [:]
    ) async throws {
        let _: [ProposalSystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [ProposalSystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body, meta: meta)],
            select: "id"
        )
    }

    private func proposalQueryItems(proposalID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func cancelApprovalQueryItems(proposalID: UUID, userID: UUID) -> [URLQueryItem] {
        let viewer = userID.uuidString.lowercased()
        return [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(ProposalStatus.agreed.rawValue)"),
            URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func evidencePhotoDeleteQueryItems(userID: UUID, proposalID: UUID, photoID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(photoID.uuidString.lowercased())"),
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "taken_by", value: "eq.\(userID.uuidString.lowercased())")
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
