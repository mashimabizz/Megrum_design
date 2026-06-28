import Foundation
import MegrumCore

public final class SupabaseBlockClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func blockUser(blockerID: UUID, blockedID: UUID) async throws -> BlockedUser {
        let rows: [BlockMutationRow] = try await client.upsertRows(
            into: "groom_user_blocks",
            values: [BlockPayload(blockerId: blockerID, blockedId: blockedID)],
            select: "blocked_id,created_at",
            onConflict: "blocker_id,blocked_id"
        )
        let row = rows.first
        return BlockedUser(
            userID: row?.blockedId ?? blockedID,
            handle: "blocked_user",
            displayName: "ブロック中のユーザー",
            blockedAt: row?.createdAt ?? .now
        )
    }

    public func loadBlockedUsers(blockerID: UUID) async throws -> [BlockedUser] {
        let blockRows: [BlockRow] = try await client.fetchRows(
            from: "groom_user_blocks",
            select: "blocked_id,created_at",
            queryItems: blockQueryItems(blockerID: blockerID)
        )
        let blockedIDs = blockRows.map(\.blockedId)
        guard !blockedIDs.isEmpty else {
            return []
        }

        let profileRows: [BlockedProfileRow] = try await client.fetchRows(
            from: "users",
            select: "id,handle,display_name,avatar_url",
            queryItems: [
                URLQueryItem(name: "id", value: "in.(\(blockedIDs.map { $0.uuidString.lowercased() }.joined(separator: ",")))")
            ]
        )
        let profilesByID = Dictionary(uniqueKeysWithValues: profileRows.map { ($0.id, $0) })
        return blockRows.map { row in
            let profile = profilesByID[row.blockedId]
            return BlockedUser(
                userID: row.blockedId,
                handle: profile?.handle ?? "blocked_user",
                displayName: profile?.displayName ?? profile?.handle ?? "ブロック中のユーザー",
                avatarURL: profile?.avatarUrl,
                blockedAt: row.createdAt
            )
        }
    }

    public func loadBlockedUserIDs(userID: UUID) async throws -> Set<UUID> {
        let rows: [BlockRelationRow] = try await client.fetchRows(
            from: "groom_user_blocks",
            select: "blocker_id,blocked_id",
            queryItems: blockedUserIDQueryItems(userID: userID)
        )
        return Set(
            rows.flatMap { [$0.blockerId, $0.blockedId] }
                .filter { $0 != userID }
        )
    }

    public func unblockUser(blockerID: UUID, blockedID: UUID) async throws {
        try await client.deleteRows(
            from: "groom_user_blocks",
            queryItems: unblockQueryItems(blockerID: blockerID, blockedID: blockedID)
        )
    }

    public func makeBlockUserRequest(blockerID: UUID, blockedID: UUID) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "groom_user_blocks",
            values: [BlockPayload(blockerId: blockerID, blockedId: blockedID)],
            select: "blocked_id,created_at",
            onConflict: "blocker_id,blocked_id"
        )
    }

    public func makeLoadBlocksRequest(blockerID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_user_blocks",
            queryItems: [
                URLQueryItem(name: "select", value: "blocked_id,created_at")
            ] + blockQueryItems(blockerID: blockerID)
        )
    }

    public func makeLoadBlockedUserIDsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_user_blocks",
            queryItems: [
                URLQueryItem(name: "select", value: "blocker_id,blocked_id")
            ] + blockedUserIDQueryItems(userID: userID)
        )
    }

    public func makeLoadBlockedProfilesRequest(userIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/users",
            queryItems: [
                URLQueryItem(name: "select", value: "id,handle,display_name,avatar_url"),
                URLQueryItem(name: "id", value: "in.(\(userIDs.map { $0.uuidString.lowercased() }.joined(separator: ",")))")
            ]
        )
    }

    public func makeUnblockRequest(blockerID: UUID, blockedID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/groom_user_blocks",
            queryItems: unblockQueryItems(blockerID: blockerID, blockedID: blockedID),
            method: "DELETE",
            body: nil,
            prefer: "return=minimal"
        )
    }

    private func blockQueryItems(blockerID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "blocker_id", value: "eq.\(blockerID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
    }

    private func blockedUserIDQueryItems(userID: UUID) -> [URLQueryItem] {
        let normalizedID = userID.uuidString.lowercased()
        return [
            URLQueryItem(name: "or", value: "(blocker_id.eq.\(normalizedID),blocked_id.eq.\(normalizedID))")
        ]
    }

    private func unblockQueryItems(blockerID: UUID, blockedID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "blocker_id", value: "eq.\(blockerID.uuidString.lowercased())"),
            URLQueryItem(name: "blocked_id", value: "eq.\(blockedID.uuidString.lowercased())")
        ]
    }
}

private struct BlockRow: Decodable, Sendable {
    var blockedId: UUID
    var createdAt: Date?
}

private struct BlockMutationRow: Decodable, Sendable {
    var blockedId: UUID
    var createdAt: Date?
}

private struct BlockRelationRow: Decodable, Sendable {
    var blockerId: UUID
    var blockedId: UUID
}

private struct BlockPayload: Encodable, Sendable {
    var blockerId: UUID
    var blockedId: UUID
}

private struct BlockedProfileRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
}
