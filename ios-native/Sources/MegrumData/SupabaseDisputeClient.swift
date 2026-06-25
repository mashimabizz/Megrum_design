import Foundation
import MegrumCore

public final class SupabaseDisputeClient: @unchecked Sendable {
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

    public func loadDisputes(proposalID: UUID, limit: Int = 10) async throws -> [SupabaseDisputeDetail] {
        let rows: [DisputeDetailRow] = try await client.fetchRows(
            from: "disputes",
            select: DisputeDetailRow.select,
            queryItems: proposalDisputesQueryItems(proposalID: proposalID, limit: limit)
        )
        return rows.map(\.detail)
    }

    public func loadDispute(ticketID: UUID) async throws -> SupabaseDisputeDetail? {
        let rows: [DisputeDetailRow] = try await client.fetchRows(
            from: "disputes",
            select: DisputeDetailRow.select,
            queryItems: ticketDisputeQueryItems(ticketID: ticketID)
        )
        return rows.first?.detail
    }

    public func createDispute(userID: UUID, input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        let proposal = try await loadProposal(proposalID: input.proposalID)
        return try await createDispute(userID: userID, proposal: proposal, input: input)
    }

    public func createDispute(
        userID: UUID,
        proposal: TradeProposal,
        input: TradeDisputeCreateInput
    ) async throws -> TradeDisputeTicket {
        guard proposal.isParticipant(userID) else {
            throw SupabaseDisputeClientError.notParticipant
        }
        guard let respondentID = proposal.partnerID(for: userID) else {
            throw SupabaseDisputeClientError.missingRespondent
        }
        let factMemo = SupabaseTextNormalizer.trimmed(input.factMemo)
        guard !factMemo.isEmpty else {
            throw SupabaseDisputeClientError.emptyFactMemo
        }

        let ticketNo = Self.makeTicketNo()
        let rows: [DisputeRow] = try await client.insertRows(
            into: "disputes",
            values: [
                DisputeInsertPayload(
                    proposalID: input.proposalID,
                    reporterID: userID,
                    respondentID: respondentID,
                    category: input.category.rawValue,
                    factMemo: factMemo,
                    evidencePhotoUrls: [],
                    ticketNo: ticketNo
                )
            ],
            select: DisputeRow.select
        )
        guard let ticket = rows.first?.ticket(proposalID: input.proposalID) else {
            throw SupabaseDisputeClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: "取引の申告を受け付けました（\(ticket.ticketNo)）"
        )
        return ticket
    }

    public func createDisputeReply(_ input: SupabaseDisputeReplyCreateInput) async throws -> SupabaseDisputeMessage {
        try validateReply(input)
        let rows: [DisputeMessageRow] = try await client.insertRows(
            into: "dispute_messages",
            values: [DisputeReplyInsertPayload(input: input)],
            select: DisputeMessageRow.select
        )
        guard let message = rows.first?.message else {
            throw SupabaseDisputeClientError.malformedResponse
        }
        if input.senderRole == .respondent {
            _ = try await markRespondentReplyReceived(input, respondedAt: message.createdAt)
        }
        return message
    }

    @discardableResult
    public func markRespondentReplyReceived(
        _ input: SupabaseDisputeReplyCreateInput,
        respondedAt: Date = .now
    ) async throws -> SupabaseDisputeDetail? {
        try validateReply(input)
        let rows: [DisputeDetailRow] = try await client.updateRows(
            in: "disputes",
            values: DisputeRespondentReplyPayload(input: input, respondedAt: SupabaseDateEncoding.isoTimestamp(respondedAt)),
            select: DisputeDetailRow.select,
            queryItems: respondentReplyQueryItems(ticketID: input.disputeID, respondentID: input.senderID)
        )
        return rows.first?.detail
    }

    @discardableResult
    public func withdrawDispute(
        ticketID: UUID,
        reporterID: UUID,
        closedAt: Date = .now
    ) async throws -> SupabaseDisputeDetail? {
        let rows: [DisputeDetailRow] = try await client.updateRows(
            in: "disputes",
            values: DisputeWithdrawPayload(closedAt: SupabaseDateEncoding.isoTimestamp(closedAt)),
            select: DisputeDetailRow.select,
            queryItems: withdrawQueryItems(ticketID: ticketID, reporterID: reporterID)
        )
        return rows.first?.detail
    }
}
