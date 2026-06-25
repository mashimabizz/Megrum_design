import Foundation
import MegrumCore

public final class SupabaseDisputeClient: @unchecked Sendable {
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

    public func makeLoadDisputesRequest(proposalID: UUID, limit: Int = 10) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + proposalDisputesQueryItems(proposalID: proposalID, limit: limit)
        )
    }

    public func makeLoadDisputeRequest(ticketID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + ticketDisputeQueryItems(ticketID: ticketID)
        )
    }

    public func makeCreateDisputeRequest(
        userID: UUID,
        proposal: TradeProposal,
        input: TradeDisputeCreateInput,
        ticketNo: String
    ) throws -> URLRequest {
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
        return try client.makeInsertRequest(
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
    }

    public func makeCreateDisputeReplyRequest(_ input: SupabaseDisputeReplyCreateInput) throws -> URLRequest {
        try validateReply(input)
        return try client.makeInsertRequest(
            into: "dispute_messages",
            values: [DisputeReplyInsertPayload(input: input)],
            select: DisputeMessageRow.select
        )
    }

    public func makeMarkRespondentReplyReceivedRequest(
        _ input: SupabaseDisputeReplyCreateInput,
        respondedAt: Date
    ) throws -> URLRequest {
        try validateReply(input)
        return try client.makeMutationRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + respondentReplyQueryItems(ticketID: input.disputeID, respondentID: input.senderID),
            method: "PATCH",
            body: encoder.encode(DisputeRespondentReplyPayload(input: input, respondedAt: SupabaseDateEncoding.isoTimestamp(respondedAt))),
            prefer: "return=representation"
        )
    }

    public func makeWithdrawDisputeRequest(
        ticketID: UUID,
        reporterID: UUID,
        closedAt: Date
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + withdrawQueryItems(ticketID: ticketID, reporterID: reporterID),
            method: "PATCH",
            body: encoder.encode(DisputeWithdrawPayload(closedAt: SupabaseDateEncoding.isoTimestamp(closedAt))),
            prefer: "return=representation"
        )
    }

    private func proposalDisputesQueryItems(proposalID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "submitted_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    private func ticketDisputeQueryItems(ticketID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func withdrawQueryItems(ticketID: UUID, reporterID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "reporter_id", value: "eq.\(reporterID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "neq.closed")
        ]
    }

    private func respondentReplyQueryItems(ticketID: UUID, respondentID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "respondent_id", value: "eq.\(respondentID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "in.(submitted,response_pending)")
        ]
    }

    private func validateReply(_ input: SupabaseDisputeReplyCreateInput) throws {
        let body = SupabaseTextNormalizer.trimmed(input.body)
        guard !body.isEmpty else {
            throw SupabaseDisputeClientError.emptyReplyBody
        }
        guard body.count <= 4_000 else {
            throw SupabaseDisputeClientError.replyBodyTooLong(maxLength: 4_000)
        }
    }

    private func loadProposal(proposalID: UUID) async throws -> TradeProposal {
        let rows: [DisputeProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: DisputeProposalRow.select,
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let proposal = rows.first?.proposal else {
            throw SupabaseDisputeClientError.proposalNotFound
        }
        return proposal
    }

    private func createSystemMessage(proposalID: UUID, senderID: UUID, body: String) async throws {
        let _: [DisputeSystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [DisputeSystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body)],
            select: "id"
        )
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private static func makeTicketNo(now: Date = .now, id: UUID = UUID()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyMMdd"
        return "DPT-\(formatter.string(from: now))-\(id.uuidString.prefix(8).uppercased())"
    }
}
