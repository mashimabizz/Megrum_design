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

    public func unblockUser(blockerID: UUID, blockedID: UUID) async throws {
        try await client.deleteRows(
            from: "groom_user_blocks",
            queryItems: unblockQueryItems(blockerID: blockerID, blockedID: blockedID)
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

private struct BlockedProfileRow: Decodable, Sendable {
    var id: UUID
    var handle: String?
    var displayName: String?
    var avatarUrl: URL?
}
