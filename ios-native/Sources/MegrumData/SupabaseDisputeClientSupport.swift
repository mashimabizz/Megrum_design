import Foundation
import MegrumCore

extension SupabaseDisputeClient {
    func proposalDisputesQueryItems(proposalID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "submitted_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    func ticketDisputeQueryItems(ticketID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func withdrawQueryItems(ticketID: UUID, reporterID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "reporter_id", value: "eq.\(reporterID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "neq.closed")
        ]
    }

    func respondentReplyQueryItems(ticketID: UUID, respondentID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "respondent_id", value: "eq.\(respondentID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "in.(submitted,response_pending)")
        ]
    }

    func validateReply(_ input: SupabaseDisputeReplyCreateInput) throws {
        let body = SupabaseTextNormalizer.trimmed(input.body)
        guard !body.isEmpty else {
            throw SupabaseDisputeClientError.emptyReplyBody
        }
        guard body.count <= 4_000 else {
            throw SupabaseDisputeClientError.replyBodyTooLong(maxLength: 4_000)
        }
    }

    func loadProposal(proposalID: UUID) async throws -> TradeProposal {
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

    func createSystemMessage(proposalID: UUID, senderID: UUID, body: String) async throws {
        let _: [DisputeSystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [DisputeSystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body)],
            select: "id"
        )
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    static func makeTicketNo(now: Date = .now, id: UUID = UUID()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyMMdd"
        return "DPT-\(formatter.string(from: now))-\(id.uuidString.prefix(8).uppercased())"
    }
}
