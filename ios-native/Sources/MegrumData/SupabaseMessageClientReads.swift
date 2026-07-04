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

    /// 一覧表示時の先読み用：複数proposalのメッセージをまとめて取得する。
    /// `limit` は全proposal合算の上限（新しい順に取得して proposal ごとへ古い順で整列）。
    public func loadMessagesBulk(proposalIDs: [UUID], limit: Int = 1_000) async throws -> [UUID: [TradeMessage]] {
        guard !proposalIDs.isEmpty else {
            return [:]
        }
        let idList = proposalIDs.map { $0.uuidString.lowercased() }.joined(separator: ",")
        let rows: [MessageRow] = try await client.fetchRows(
            from: "messages",
            select: MessageRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "in.(\(idList))"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "\(max(1, limit))")
            ]
        )
        let messages = await refreshedMessages(from: rows)
        return Dictionary(grouping: messages, by: \.proposalID)
            .mapValues { $0.sorted { $0.createdAt < $1.createdAt } }
    }

    /// 一覧表示時の先読み用：自分の既読状態をまとめて取得する。
    public func loadReadStates(proposalIDs: [UUID], userID: UUID) async throws -> [UUID: Date] {
        guard !proposalIDs.isEmpty else {
            return [:]
        }
        let idList = proposalIDs.map { $0.uuidString.lowercased() }.joined(separator: ",")
        do {
            let rows: [ProposalReadStateRow] = try await client.fetchRows(
                from: "proposal_read_states",
                select: ProposalReadStateRow.select,
                queryItems: [
                    URLQueryItem(name: "proposal_id", value: "in.(\(idList))"),
                    URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
                ]
            )
            return rows.compactMap(\.readState).reduce(into: [:]) { result, state in
                result[state.proposalID] = state.lastReadAt
            }
        } catch let error as SupabaseRESTError where Self.isOptionalReadStateError(error) {
            return [:]
        }
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
