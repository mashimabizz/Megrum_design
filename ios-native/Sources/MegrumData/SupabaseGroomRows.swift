import Foundation
import MegrumCore

struct GroomFeedPayload: Encodable, Sendable {
    var pViewerLat: Double?
    var pViewerLng: Double?
    var pRadiusM: Int

    init(latitude: Double?, longitude: Double?, radiusMeters: Int, maxRadiusMeters: Int, minRadiusMeters: Int) {
        self.pViewerLat = latitude
        self.pViewerLng = longitude
        self.pRadiusM = min(max(radiusMeters, minRadiusMeters), maxRadiusMeters)
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

struct GroomFeedRow: Decodable, Sendable {
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
        if let storageImagePath, let signedURL = signedURLs[storageImagePath] {
            return signedURL
        }
        if let imageUrl = normalizedImageURL, let url = URL(string: imageUrl) {
            return url
        }
        if let storageImagePath {
            return URL(string: storageImagePath)
        }
        return nil
    }

    var storageImagePath: String? {
        if let imagePath = SupabaseTextNormalizer.optional(imagePath) {
            return imagePath
        }
        guard let imageUrl = SupabaseTextNormalizer.optional(imageUrl) else {
            return nil
        }
        if URL(string: imageUrl)?.scheme == nil {
            return imageUrl
        }
        return nil
    }

    func isWithinRadius(latitude: Double?, longitude: Double?, radiusMeters: Double) -> Bool {
        guard
            let latitude,
            let longitude,
            let originLat,
            let originLng
        else {
            return true
        }
        return haversineMeters(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: originLat,
            toLongitude: originLng
        ) <= radiusMeters
    }

    private var normalizedImageURL: String? {
        SupabaseTextNormalizer.optional(imageUrl)
    }
}

struct GroomPostInsertPayload: Encodable, Sendable {
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
        self.caption = input.caption.map(SupabaseTextNormalizer.trimmed)
        self.imagePath = imagePath
        self.imageUrl = imagePath
        self.originLat = input.latitude
        self.originLng = input.longitude
        self.placeHint = input.placeHint.map(SupabaseTextNormalizer.trimmed) ?? "今日の現場付近"
        self.userId = input.authorID
    }
}

struct GroomImageTransformPayload: Encodable, Sendable {
    var rotation = 0
    var scale = 1
    var x = 0
    var y = 0
}

struct GroomViewPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
}

struct GroomViewRow: Decodable, Sendable {
    var groomPostID: UUID?
    var userID: UUID?
}

struct GroomReactionPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
    var reactionType = "like"
}

struct GroomReactionRow: Decodable, Sendable {
    static let select = [
        "groom_post_id",
        "user_id",
        "reaction_type",
        "created_at"
    ].joined(separator: ",")

    var groomPostID: UUID
    var userID: UUID
    var reactionType: String?
    var createdAt: Date?

    var reaction: GroomReaction {
        GroomReaction(
            groomPostID: groomPostID,
            userID: userID,
            reactionType: reactionType ?? "like",
            createdAt: createdAt ?? .now
        )
    }
}

struct GroomReplyPayload: Encodable, Sendable {
    var body: String
    var groomPostID: UUID
    var groomSnapshot: GroomSnapshotPayload
    var recipientID: UUID
    var senderID: UUID

    init(input: GroomReplyCreateInput) {
        self.body = SupabaseTextNormalizer.trimmed(input.body)
        self.groomPostID = input.groomPostID
        self.groomSnapshot = GroomSnapshotPayload(imageURL: input.groomImageURL)
        self.recipientID = input.recipientID
        self.senderID = input.senderID
    }
}

struct GroomSnapshotPayload: Encodable, Sendable {
    var caption = ""
    var imagePath: String?
    var imageURL: String?

    init(imageURL: URL?) {
        self.imageURL = imageURL?.absoluteString
    }
}

struct GroomReplyRow: Decodable, Sendable {
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

struct GroomSnapshotRow: Decodable, Sendable {
    var imageUrl: String?
    var imagePath: String?

    var resolvedImageURL: URL? {
        guard let imageUrl else {
            return nil
        }
        return URL(string: imageUrl)
    }
}

struct GroomReplyNotificationPayload: Encodable, Sendable {
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

struct GroomNotificationAckRow: Decodable, Sendable {
    var id: UUID?
}

private func haversineMeters(
    fromLatitude: Double,
    fromLongitude: Double,
    toLatitude: Double,
    toLongitude: Double
) -> Double {
    let earthRadius = 6_371_000.0
    let fromLat = fromLatitude * .pi / 180
    let toLat = toLatitude * .pi / 180
    let deltaLat = (toLatitude - fromLatitude) * .pi / 180
    let deltaLng = (toLongitude - fromLongitude) * .pi / 180
    let a = sin(deltaLat / 2) * sin(deltaLat / 2)
        + cos(fromLat) * cos(toLat) * sin(deltaLng / 2) * sin(deltaLng / 2)
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
}
