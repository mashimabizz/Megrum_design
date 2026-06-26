import Foundation
import MegrumCore

extension SupabaseMessageClient {
    public func loadMessages(proposalID: UUID, limit: Int = 80) async throws -> [TradeMessage] {
        let rows: [MessageRow] = try await client.fetchRows(
            from: "messages",
            select: MessageRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "\(max(1, min(limit, 120)))")
            ]
        )
        return await refreshedMessages(from: rows)
    }

    public func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState? {
        do {
            let rows: [ProposalReadStateRow] = try await client.fetchRows(
                from: "proposal_read_states",
                select: ProposalReadStateRow.select,
                queryItems: [
                    URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                    URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
            return rows.first?.readState
        } catch let error as SupabaseRESTError where Self.isOptionalReadStateError(error) {
            return nil
        }
    }

    public func markProposalMessagesRead(
        proposalID: UUID,
        userID: UUID,
        lastReadAt: Date,
        updatedAt: Date = .now
    ) async throws -> ProposalReadState? {
        do {
            let rows: [ProposalReadStateRow] = try await client.upsertRows(
                into: "proposal_read_states",
                values: [
                    ProposalReadStateUpsertPayload(
                        proposalID: proposalID,
                        userID: userID,
                        lastReadAt: lastReadAt,
                        updatedAt: updatedAt
                    )
                ],
                select: ProposalReadStateRow.select,
                onConflict: "proposal_id,user_id"
            )
            return rows.first?.readState
        } catch let error as SupabaseRESTError where Self.isOptionalReadStateError(error) {
            return nil
        }
    }
}
