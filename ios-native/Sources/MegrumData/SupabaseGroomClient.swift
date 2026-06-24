import Foundation
import MegrumCore

public enum SupabaseGroomClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case malformedResponse
}

public final class SupabaseGroomClient: @unchecked Sendable {
    private static let groomBucket = "groom-posts"
    private static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
    private static let maxFeedRadiusMeters = 1_000
    private static let maxMapRadiusMeters = 3_000
    private static let minRadiusMeters = 100
    private let client: SupabaseRESTClient

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

    public func makeLoadNearbyGroomsRequest(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 1_000
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxFeedRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
    }

    public func makeLoadGroomMapPostsRequest(
        latitude: Double?,
        longitude: Double?,
        radiusMeters: Int = 3_000
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_groom_feed_nearby",
            payload: GroomFeedPayload(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                maxRadiusMeters: Self.maxMapRadiusMeters,
                minRadiusMeters: Self.minRadiusMeters
            )
        )
    }

    public func makeLoadOwnGroomArchiveRequest(userID: UUID, limit: Int = 120) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_posts",
            queryItems: [URLQueryItem(name: "select", value: GroomFeedRow.select)]
                + ownGroomArchiveQueryItems(userID: userID, limit: limit)
        )
    }

    public func makeLoadReactionsRequest(postIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_reactions",
            queryItems: [URLQueryItem(name: "select", value: GroomReactionRow.select)]
                + engagementQueryItems(postIDs: postIDs, order: "created_at.desc") + [
                    URLQueryItem(name: "reaction_type", value: "eq.like")
                ]
        )
    }

    public func makeLoadRepliesRequest(postIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groom_replies",
            queryItems: [URLQueryItem(name: "select", value: GroomReplyRow.select)]
                + engagementQueryItems(postIDs: postIDs, order: "created_at.desc")
        )
    }

    public func makeCreatePostRequest(_ input: GroomPostCreateInput, imagePath: String) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "groom_posts",
            values: [GroomPostInsertPayload(input: input, imagePath: imagePath)],
            select: GroomFeedRow.select
        )
    }

    public func markViewed(userID: UUID, postID: UUID) async throws {
        let _: [GroomViewRow] = try await client.upsertRows(
            into: "groom_views",
            values: [GroomViewPayload(groomPostID: postID, userID: userID)],
            onConflict: "groom_post_id,user_id"
        )
    }

    public func setLiked(userID: UUID, postID: UUID, isLiked: Bool) async throws {
        if isLiked {
            let _: [GroomReactionRow] = try await client.upsertRows(
                into: "groom_reactions",
                values: [GroomReactionPayload(groomPostID: postID, userID: userID)],
                onConflict: "groom_post_id,user_id,reaction_type"
            )
        } else {
            try await client.deleteRows(
                from: "groom_reactions",
                queryItems: [
                    URLQueryItem(name: "groom_post_id", value: "eq.\(postID.uuidString.lowercased())"),
                    URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
                    URLQueryItem(name: "reaction_type", value: "eq.like")
                ]
            )
        }
    }

    public func makeMarkViewedRequest(userID: UUID, postID: UUID) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "groom_views",
            values: [GroomViewPayload(groomPostID: postID, userID: userID)],
            onConflict: "groom_post_id,user_id"
        )
    }

    public func makeSetLikedRequest(userID: UUID, postID: UUID, isLiked: Bool) throws -> URLRequest {
        if isLiked {
            return try client.makeUpsertRequest(
                into: "groom_reactions",
                values: [GroomReactionPayload(groomPostID: postID, userID: userID)],
                onConflict: "groom_post_id,user_id,reaction_type"
            )
        }
        return try client.makeDeleteRequest(
            from: "groom_reactions",
            queryItems: [
                URLQueryItem(name: "groom_post_id", value: "eq.\(postID.uuidString.lowercased())"),
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
                URLQueryItem(name: "reaction_type", value: "eq.like")
            ]
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
        try? await createReplyNotification(reply: reply)
        return reply
    }

    public func makeSendReplyRequest(_ input: GroomReplyCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "groom_replies",
            values: [GroomReplyPayload(input: input)],
            select: GroomReplyRow.select
        )
    }

    public func makeReplyNotificationRequest(reply: GroomReply) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "notifications",
            values: [GroomReplyNotificationPayload(reply: reply)],
            select: "id"
        )
    }

    private func signedURLMap(for rows: [GroomFeedRow]) async -> [String: URL] {
        var signedURLs: [String: URL] = [:]
        let paths = Set(rows.compactMap(\.storageImagePath))
        for path in paths {
            signedURLs[path] = try? await client.createSignedURL(bucket: Self.groomBucket, path: path)
        }
        return signedURLs
    }

    private func createReplyNotification(reply: GroomReply) async throws {
        let _: [GroomNotificationAckRow] = try await client.insertRows(
            into: "notifications",
            values: [GroomReplyNotificationPayload(reply: reply)],
            select: "id"
        )
    }

    private func ownGroomArchiveQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.published"),
            URLQueryItem(name: "order", value: "published_at.desc.nullslast,created_at.desc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 300)))")
        ]
    }

    private func engagementQueryItems(postIDs: [UUID], order: String) -> [URLQueryItem] {
        let ids = postIDs
            .map { $0.uuidString.lowercased() }
            .sorted()
            .joined(separator: ",")
        return [
            URLQueryItem(name: "groom_post_id", value: "in.(\(ids))"),
            URLQueryItem(name: "order", value: order)
        ]
    }

    private func groomImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }
}
