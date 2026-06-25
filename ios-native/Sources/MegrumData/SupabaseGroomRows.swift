import Foundation
import MegrumCore

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

struct GroomViewRow: Decodable, Sendable {
    var groomPostID: UUID?
    var userID: UUID?
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
