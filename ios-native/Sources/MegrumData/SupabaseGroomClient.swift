import Foundation
import MegrumCore

public enum SupabaseGroomClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case malformedResponse
}

public final class SupabaseGroomClient: @unchecked Sendable {
    static let groomBucket = "groom-posts"
    static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
    static let maxFeedRadiusMeters = 1_000
    /// 地図のビューポート読み込み上限。サーバー側の list_groom_feed_nearby も
    /// 100km で頭打ちにしている（20260704150000 migration）。
    static let maxMapRadiusMeters = 100_000
    static let minRadiusMeters = 100
    let client: SupabaseRESTClient
    let signedURLCache = SupabaseGroomSignedURLCache()

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadNearbyGrooms(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 1_000
    ) async throws -> [GroomPost] {
        let rows: [GroomFeedRow] = try await client.rpcRows(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxFeedRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
        let scopedRows = rows.filter {
            $0.isWithinRadius(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: Double(Self.maxFeedRadiusMeters)
            )
        }
        let signedURLs = await signedURLMap(for: scopedRows)
        return scopedRows.compactMap { $0.post(signedURLs: signedURLs) }
    }

    public func loadGroomMapPosts(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 3_000
    ) async throws -> [GroomPost] {
        let rows: [GroomFeedRow] = try await client.rpcRows(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxMapRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
        let signedURLs = await signedURLMap(for: rows)
        return rows.compactMap { $0.post(signedURLs: signedURLs) }
    }

    public func loadOwnGroomArchive(userID: UUID, limit: Int = 120) async throws -> [GroomPost] {
        let rows: [GroomFeedRow] = try await client.fetchRows(
            from: "groom_posts",
            select: GroomFeedRow.select,
            queryItems: ownGroomArchiveQueryItems(userID: userID, limit: limit)
        )
        let signedURLs = await signedURLMap(for: rows)
        return rows.compactMap { $0.post(signedURLs: signedURLs) }
    }

    public func loadReactions(postIDs: [UUID]) async throws -> [GroomReaction] {
        guard !postIDs.isEmpty else {
            return []
        }
        let rows: [GroomReactionRow] = try await client.fetchRows(
            from: "groom_reactions",
            select: GroomReactionRow.select,
            queryItems: engagementQueryItems(postIDs: postIDs, order: "created_at.desc") + [
                URLQueryItem(name: "reaction_type", value: "eq.like")
            ]
        )
        return rows.map(\.reaction)
    }

    public func loadReplies(postIDs: [UUID]) async throws -> [GroomReply] {
        guard !postIDs.isEmpty else {
            return []
        }
        let rows: [GroomReplyRow] = try await client.fetchRows(
            from: "groom_replies",
            select: GroomReplyRow.select,
            queryItems: engagementQueryItems(postIDs: postIDs, order: "created_at.desc")
        )
        return rows.map(\.reply)
    }

    public func createPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        guard input.imageData.count <= Self.maxUploadBytes else {
            throw SupabaseGroomClientError.imageTooLarge
        }

        let contentType = SupabaseImageContentTypeNormalizer.lenient(input.imageContentType)
        let imagePath = groomImagePath(userID: input.authorID, contentType: contentType)
        try await client.uploadObject(
            bucket: Self.groomBucket,
            path: imagePath,
            data: input.imageData,
            contentType: contentType,
            upsert: false
        )

        let rows: [GroomFeedRow] = try await client.insertRows(
            into: "groom_posts",
            values: [GroomPostInsertPayload(input: input, imagePath: imagePath)],
            select: GroomFeedRow.select
        )
        let signedURLs = await signedURLMap(for: rows)
        guard let post = rows.first?.post(signedURLs: signedURLs) else {
            throw SupabaseGroomClientError.malformedResponse
        }
        return post
    }

    public func deletePost(userID: UUID, postID: UUID) async throws {
        let _: [GroomPostDeleteRow] = try await client.updateRows(
            in: "groom_posts",
            values: GroomPostDeletePayload(),
            select: "id",
            queryItems: ownGroomPostQueryItems(userID: userID, postID: postID)
        )
    }

    public func markViewed(userID: UUID, postID: UUID) async throws {
        let _: [GroomViewRow] = try await client.upsertRows(
            into: "groom_views",
            values: [GroomViewPayload(groomPostID: postID, userID: userID)],
            onConflict: "groom_post_id,user_id"
        )
    }

    public func setLiked(userID _: UUID, postID: UUID, isLiked: Bool) async throws {
        try await client.rpcVoid(
            function: "set_groom_like_for_viewer",
            payload: GroomLikeTogglePayload(pPostID: postID, pIsLiked: isLiked)
        )
    }

    public func reportPost(reporterID: UUID, input: GroomReportCreateInput) async throws -> GroomReportTicket {
        let rows: [GroomReportRow] = try await client.insertRows(
            into: "groom_reports",
            values: [GroomReportPayload(reporterID: reporterID, input: input)],
            select: GroomReportRow.select
        )
        return rows.first?.ticket ?? GroomReportTicket(
            id: UUID(),
            groomPostID: input.groomPostID,
            reportedUserID: input.reportedUserID,
            reason: input.reason
        )
    }

    public func blockUser(blockerID: UUID, blockedID: UUID) async throws {
        let _: [GroomBlockRow] = try await client.upsertRows(
            into: "groom_user_blocks",
            values: [GroomBlockPayload(blockedID: blockedID, blockerID: blockerID)],
            select: "blocked_id",
            onConflict: "blocker_id,blocked_id"
        )
    }

    public func sendReply(_ input: GroomReplyCreateInput) async throws -> GroomReply {
        let rows: [GroomReplyRow] = try await client.insertRows(
            into: "groom_replies",
            values: [GroomReplyPayload(input: input)],
            select: GroomReplyRow.select
        )
        guard let reply = rows.first?.reply else {
            throw SupabaseGroomClientError.malformedResponse
        }
        try? await createReplyMeguriMessage(reply: reply)
        return reply
    }

    private func createReplyMeguriMessage(reply: GroomReply) async throws {
        let _: [EmptyInsertResult] = try await client.insertRows(
            into: "meguri_messages",
            values: [GroomReplyMeguriMessagePayload(reply: reply)],
            select: "id"
        )
    }

}

private struct EmptyInsertResult: Decodable, Sendable {}
