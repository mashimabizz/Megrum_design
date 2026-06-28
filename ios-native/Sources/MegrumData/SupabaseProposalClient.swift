import Foundation
import MegrumCore

public final class SupabaseProposalClient: @unchecked Sendable {
    static let chatPhotoBucket = "chat-photos"
    static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
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
        let queryItems = [
            URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
            URLQueryItem(name: "order", value: "updated_at.desc.nullslast,created_at.desc")
        ]
        let rows: [ProposalRow]
        do {
            rows = try await client.fetchRows(
                from: "proposals",
                select: ProposalRow.select,
                queryItems: queryItems
            )
        } catch {
            rows = try await client.fetchRows(
                from: "proposals",
                select: ProposalRow.legacySelect,
                queryItems: queryItems
            )
        }
        return rows.compactMap(\.proposal)
    }

    public func createProposal(senderID: UUID, input: ProposalCreateInput, now: Date = .now) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.upsertRows(
            into: "proposals",
            values: [try ProposalCreatePayload(senderID: senderID, input: input, now: now)],
            select: ProposalRow.legacySelect
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
            updatedAt: now,
            meetupCandidates: input.meetupCandidates.isEmpty ? input.meetup.map { [$0] } : input.meetupCandidates
        )
    }

    public func reviseProposal(
        userID: UUID,
        proposalID: UUID,
        input: ProposalCreateInput,
        now: Date = .now
    ) async throws -> TradeProposal {
        let current = try await loadProposal(proposalID: proposalID)
        guard current.isParticipant(userID), input.receiverID == current.partnerID(for: userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard current.allowsCounterProposal else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: try ProposalRevisionPayload(senderID: userID, input: input, now: now),
            select: ProposalRow.select,
            queryItems: participantProposalQueryItems(proposalID: proposalID, userID: userID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        return updated
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

    public func approveEvidence(userID: UUID, proposalID: UUID, photoID: UUID? = nil) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.rpcRows(
            function: "approve_trade_evidence_for_viewer",
            payload: ProposalApprovalRPCPayload(proposalID: proposalID, photoID: photoID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: proposalID,
            senderID: userID,
            body: updated.status == .completed ? "取引が完了しました" : "証跡写真を承認しました",
            meta: updated.status == .completed ? ["action": SupabaseProposalSystemAction.tradeCompleted.rawValue] : [:]
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
        var meta: [String: String] = [
            "action": SupabaseProposalSystemAction.evaluationSubmitted.rawValue,
            "stars": "\(evaluation.stars)",
            "rater_id": userID.uuidString.lowercased()
        ]
        if let comment = SupabaseTextNormalizer.optional(evaluation.comment) {
            meta["comment"] = comment
        }
        if let displayName = SupabaseTextNormalizer.optional(input.raterDisplayName) {
            meta["rater_display_name"] = displayName
        }
        if let handle = SupabaseTextNormalizer.optional(input.raterHandle) {
            meta["rater_handle"] = handle
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: SupabaseTextNormalizer.optional(input.systemMessageBody) ?? "評価が完了しました",
            meta: meta
        )
        return evaluation
    }

}
