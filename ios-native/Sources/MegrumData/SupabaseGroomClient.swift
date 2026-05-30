import Foundation
import MegrumCore

public enum SupabaseGroomClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case malformedResponse
}

public final class SupabaseGroomClient: @unchecked Sendable {
    private static let groomBucket = "groom-posts"
    private static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
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
                radiusMeters: radiusMeters
            )
        )
        let signedURLs = try await signedURLMap(for: rows)
        return rows.compactMap { $0.post(signedURLs: signedURLs) }
    }

    public func createPost(_ input: GroomPostCreateInput) async throws -> GroomPost {
        guard input.imageData.count <= Self.maxUploadBytes else {
            throw SupabaseGroomClientError.imageTooLarge
        }

        let contentType = normalizedImageContentType(input.imageContentType)
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
        let signedURLs = try await signedURLMap(for: rows)
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
                radiusMeters: radiusMeters
            )
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

    private func signedURLMap(for rows: [GroomFeedRow]) async throws -> [String: URL] {
        var signedURLs: [String: URL] = [:]
        for path in rows.compactMap(\.imagePath) {
            signedURLs[path] = try await client.createSignedURL(bucket: Self.groomBucket, path: path)
        }
        return signedURLs
    }

    private func createReplyNotification(reply: GroomReply) async throws {
        let _: [NotificationAckRow] = try await client.insertRows(
            into: "notifications",
            values: [GroomReplyNotificationPayload(reply: reply)],
            select: "id"
        )
    }

    private func groomImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(fileExtension(for: contentType))"
    }
}

private struct GroomFeedPayload: Encodable, Sendable {
    var pViewerLat: Double?
    var pViewerLng: Double?
    var pRadiusM: Int

    init(latitude: Double?, longitude: Double?, radiusMeters: Int) {
        self.pViewerLat = latitude
        self.pViewerLng = longitude
        self.pRadiusM = min(max(radiusMeters, 100), 1_000)
    }

    enum CodingKeys: String, CodingKey {
        case pViewerLat
        case pViewerLng
        case pRadiusM
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let pViewerLat {
            try container.encode(pViewerLat, forKey: .pViewerLat)
        } else {
            try container.encodeNil(forKey: .pViewerLat)
        }
        if let pViewerLng {
            try container.encode(pViewerLng, forKey: .pViewerLng)
        } else {
            try container.encodeNil(forKey: .pViewerLng)
        }
        try container.encode(pRadiusM, forKey: .pRadiusM)
    }
}

private struct GroomFeedRow: Decodable, Sendable {
    static let select = [
        "id",
        "user_id",
        "image_url",
        "image_path",
        "published_at",
        "created_at",
        "origin_lat",
        "origin_lng"
    ].joined(separator: ",")

    var id: UUID
    var userId: UUID
    var imageUrl: String?
    var imagePath: String?
    var publishedAt: Date?
    var createdAt: Date?
    var originLat: Double?
    var originLng: Double?

    func post(signedURLs: [String: URL] = [:]) -> GroomPost? {
        guard
            let url = resolvedImageURL(signedURLs: signedURLs),
            let latitude = originLat,
            let longitude = originLng
        else {
            return nil
        }

        return GroomPost(
            id: id,
            authorID: userId,
            imageURL: url,
            latitude: latitude,
            longitude: longitude,
            createdAt: publishedAt ?? createdAt ?? .now
        )
    }

    private func resolvedImageURL(signedURLs: [String: URL]) -> URL? {
        if let imagePath, let signedURL = signedURLs[imagePath] {
            return signedURL
        }
        guard let imageUrl, let url = URL(string: imageUrl), url.scheme != nil else {
            return nil
        }
        return url
    }
}

private struct GroomPostInsertPayload: Encodable, Sendable {
    var audienceScope = "encountered_people"
    var audienceUserIds: [UUID] = []
    var caption: String?
    var doodles: [String] = []
    var imagePath: String
    var imageTransform = GroomImageTransformPayload()
    var imageUrl: String
    var originLat: Double?
    var originLng: Double?
    var placeHint: String
    var status = "published"
    var stickers: [String] = []
    var textOverlays: [String] = []
    var userId: UUID

    init(input: GroomPostCreateInput, imagePath: String) {
        self.caption = input.caption?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.imagePath = imagePath
        self.imageUrl = imagePath
        self.originLat = input.latitude
        self.originLng = input.longitude
        self.placeHint = input.placeHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "今日の現場付近"
        self.userId = input.authorID
    }
}

private struct GroomImageTransformPayload: Encodable, Sendable {
    var rotation = 0
    var scale = 1
    var x = 0
    var y = 0
}

private struct GroomViewPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
}

private struct GroomViewRow: Decodable, Sendable {
    var groomPostID: UUID?
    var userID: UUID?
}

private struct GroomReactionPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
    var reactionType = "like"
}

private struct GroomReactionRow: Decodable, Sendable {
    var groomPostID: UUID?
    var userID: UUID?
    var reactionType: String?
}

private struct GroomReplyPayload: Encodable, Sendable {
    var body: String
    var groomPostID: UUID
    var groomSnapshot: GroomSnapshotPayload
    var recipientID: UUID
    var senderID: UUID

    init(input: GroomReplyCreateInput) {
        self.body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.groomPostID = input.groomPostID
        self.groomSnapshot = GroomSnapshotPayload(imageURL: input.groomImageURL)
        self.recipientID = input.recipientID
        self.senderID = input.senderID
    }
}

private struct GroomSnapshotPayload: Encodable, Sendable {
    var caption = ""
    var imagePath: String?
    var imageURL: String?

    init(imageURL: URL?) {
        self.imageURL = imageURL?.absoluteString
    }
}

private struct GroomReplyRow: Decodable, Sendable {
    static let select = [
        "id",
        "groom_post_id",
        "sender_id",
        "recipient_id",
        "body",
        "groom_snapshot",
        "read_at",
        "created_at"
    ].joined(separator: ",")

    var id: UUID
    var groomPostID: UUID
    var senderID: UUID
    var recipientID: UUID
    var body: String
    var groomSnapshot: GroomSnapshotRow?
    var readAt: Date?
    var createdAt: Date?

    var reply: GroomReply {
        GroomReply(
            id: id,
            groomPostID: groomPostID,
            senderID: senderID,
            recipientID: recipientID,
            body: body,
            groomImageURL: groomSnapshot?.resolvedImageURL,
            readAt: readAt,
            createdAt: createdAt ?? .now
        )
    }
}

private struct GroomSnapshotRow: Decodable, Sendable {
    var imageUrl: String?
    var imagePath: String?

    var resolvedImageURL: URL? {
        guard let imageUrl else {
            return nil
        }
        return URL(string: imageUrl)
    }
}

private struct GroomReplyNotificationPayload: Encodable, Sendable {
    var body: String
    var groomReplyID: UUID
    var kind = "groom_reply"
    var linkPath: String
    var title = "グルームに返信が届きました"
    var userID: UUID

    init(reply: GroomReply) {
        self.body = String(reply.body.prefix(120))
        self.groomReplyID = reply.id
        self.linkPath = "/meguri-letters?open=1&userId=\(reply.senderID.uuidString.lowercased())"
        self.userID = reply.recipientID
    }
}

private struct NotificationAckRow: Decodable, Sendable {
    var id: UUID?
}

private func normalizedImageContentType(_ value: String) -> String {
    switch value.lowercased() {
    case "image/png":
        "image/png"
    case "image/webp":
        "image/webp"
    default:
        "image/jpeg"
    }
}

private func fileExtension(for contentType: String) -> String {
    switch normalizedImageContentType(contentType) {
    case "image/png":
        "png"
    case "image/webp":
        "webp"
    default:
        "jpg"
    }
}
