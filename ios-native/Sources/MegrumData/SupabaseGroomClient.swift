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
    static let maxMapRadiusMeters = 3_000
    static let minRadiusMeters = 100
    let client: SupabaseRESTClient

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
}
