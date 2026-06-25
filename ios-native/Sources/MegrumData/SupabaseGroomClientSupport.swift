import Foundation
import MegrumCore

extension SupabaseGroomClient {
    func signedURLMap(for rows: [GroomFeedRow]) async -> [String: URL] {
        var signedURLs: [String: URL] = [:]
        let paths = Set(rows.compactMap(\.storageImagePath))
        for path in paths {
            signedURLs[path] = try? await client.createSignedURL(bucket: Self.groomBucket, path: path)
        }
        return signedURLs
    }

    func createReplyNotification(reply: GroomReply) async throws {
        let _: [GroomNotificationAckRow] = try await client.insertRows(
            into: "notifications",
            values: [GroomReplyNotificationPayload(reply: reply)],
            select: "id"
        )
    }

    func ownGroomArchiveQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.published"),
            URLQueryItem(name: "order", value: "published_at.desc.nullslast,created_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 300)))")
        ]
    }

    func engagementQueryItems(postIDs: [UUID], order: String) -> [URLQueryItem] {
        let ids = postIDs
            .map { $0.uuidString.lowercased() }
            .sorted()
            .joined(separator: ",")
        return [
            URLQueryItem(name: "groom_post_id", value: "in.(\(ids))"),
            URLQueryItem(name: "order", value: order)
        ]
    }

    func groomImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }
}
