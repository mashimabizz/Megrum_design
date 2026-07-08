import Foundation
import MegrumCore

struct GroomFeedRow: Decodable, Sendable {
    static let select = [
        "id",
        "user_id",
        "image_url",
        "image_path",
        "published_at",
        "expires_at",
        "created_at",
        "origin_lat",
        "origin_lng",
        "group_id",
        "character_id",
        "series_name"
    ].joined(separator: ",")

    var id: UUID
    var userId: UUID
    var imageUrl: String?
    var imagePath: String?
    var publishedAt: Date?
    var expiresAt: Date?
    var createdAt: Date?
    var originLat: Double?
    var originLng: Double?
    var groupId: UUID?
    var characterId: UUID?
    var seriesName: String?
    var likeCount: Int?
    var viewerHasLiked: Bool?
    /// FB8-7: このグルームについて自分に通知が飛んだか（フィードRPCが返す）。iter1226.388。
    var viewerWasNotified: Bool?
    /// FB(iter1226.390): 自分の1km圏内で推し一致して遭遇済みか（フィードRPCが返す）。
    var viewerEncountered: Bool?
    /// アーカイブ取得（テーブル直読み）用の埋め込みリアクション。
    var groomReactions: [GroomReactionLiteRow]?

    func post(signedURLs: [String: URL] = [:], viewerID: UUID? = nil) -> GroomPost? {
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
            groupID: groupId,
            characterID: characterId,
            seriesName: SupabaseTextNormalizer.optional(seriesName),
            createdAt: publishedAt ?? createdAt ?? .now,
            expiresAt: expiresAt,
            likeCount: max(0, likeCount ?? embeddedLikeReactions?.count ?? 0),
            liked: resolvedViewerHasLiked(viewerID: viewerID),
            encounteredInRange: viewerEncountered ?? false
        )
    }

    private var embeddedLikeReactions: [GroomReactionLiteRow]? {
        groomReactions?.filter { $0.reactionType == "like" }
    }

    private func resolvedViewerHasLiked(viewerID: UUID?) -> Bool {
        if let viewerHasLiked {
            return viewerHasLiked
        }
        guard let viewerID, let embeddedLikeReactions else {
            return false
        }
        return embeddedLikeReactions.contains { $0.userId == viewerID }
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

struct GroomPostDeleteRow: Decodable, Sendable {
    var id: UUID
}

struct GroomViewRow: Decodable, Sendable {
    var groomPostID: UUID?
    var userID: UUID?

    enum CodingKeys: String, CodingKey {
        case groomPostID = "groomPostId"
        case userID = "userId"
    }
}

struct GroomBlockRow: Decodable, Sendable {
    var blockedID: UUID?

    enum CodingKeys: String, CodingKey {
        case blockedID = "blockedId"
    }
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

    enum CodingKeys: String, CodingKey {
        case groomPostID = "groomPostId"
        case userID = "userId"
        case reactionType
        case createdAt
    }

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

    enum CodingKeys: String, CodingKey {
        case id
        case groomPostID = "groomPostId"
        case senderID = "senderId"
        case recipientID = "recipientId"
        case body
        case groomSnapshot
        case readAt
        case createdAt
    }

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

struct GroomReportRow: Decodable, Sendable {
    static let select = [
        "id",
        "groom_post_id",
        "reported_user_id",
        "reason",
        "status",
        "created_at"
    ].joined(separator: ",")

    var id: UUID
    var groomPostID: UUID
    var reportedUserID: UUID
    var reason: String?
    var status: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case groomPostID = "groomPostId"
        case reportedUserID = "reportedUserId"
        case reason
        case status
        case createdAt
    }

    var ticket: GroomReportTicket {
        GroomReportTicket(
            id: id,
            groomPostID: groomPostID,
            reportedUserID: reportedUserID,
            reason: GroomReportReason(rawValue: reason ?? "") ?? .other,
            status: status ?? "open",
            createdAt: createdAt ?? .now
        )
    }
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

struct GroomReactionLiteRow: Decodable, Sendable {
    var userId: UUID
    var reactionType: String
}
