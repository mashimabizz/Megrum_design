import Foundation
import MegrumCore

/// FB(iter1226.390): get_groom_feed_item(p_groom_id) 用ペイロード。
struct GroomFeedItemPayload: Encodable, Sendable {
    var pGroomId: UUID
}

/// FB(iter1226.392): list_encountered_grooms(p_viewer_lat, p_viewer_lng) 用ペイロード。
struct GroomEncounteredFeedPayload: Encodable, Sendable {
    var pViewerLat: Double?
    var pViewerLng: Double?

    enum CodingKeys: String, CodingKey {
        case pViewerLat
        case pViewerLng
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
    }
}

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
    var groupId: UUID?
    var characterId: UUID?
    var seriesName: String?
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
        self.groupId = input.groupID
        self.characterId = input.characterID
        self.seriesName = SupabaseTextNormalizer.optional(input.seriesName)
        self.userId = input.authorID
    }
}

struct GroomPostDeletePayload: Encodable, Sendable {
    var status = "hidden"
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

struct GroomReactionPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
    var reactionType = "like"
}

struct GroomLikeTogglePayload: Encodable, Sendable {
    var pPostID: UUID
    var pIsLiked: Bool

    enum CodingKeys: String, CodingKey {
        case pPostID
        case pIsLiked
    }
}

struct GroomReportPayload: Encodable, Sendable {
    var groomPostID: UUID
    var note: String?
    var reason: String
    var reportedUserID: UUID
    var reporterID: UUID

    init(reporterID: UUID, input: GroomReportCreateInput) {
        self.groomPostID = input.groomPostID
        self.note = SupabaseTextNormalizer.optional(input.note)
        self.reason = input.reason.rawValue
        self.reportedUserID = input.reportedUserID
        self.reporterID = reporterID
    }
}

struct GroomBlockPayload: Encodable, Sendable {
    var blockedID: UUID
    var blockerID: UUID
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

struct GroomReplyMeguriMessagePayload: Encodable, Sendable {
    var body: String
    var messageType = "text"
    var recipientID: UUID
    var senderID: UUID
    var sourceGroomReplyID: UUID
    var sourceGroomPostID: UUID
    var sourceGroomOwnerID: UUID
    var sourceGroomImageURL: String?

    init(reply: GroomReply) {
        self.body = reply.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.recipientID = reply.recipientID
        self.senderID = reply.senderID
        self.sourceGroomReplyID = reply.id
        self.sourceGroomPostID = reply.groomPostID
        self.sourceGroomOwnerID = reply.recipientID
        self.sourceGroomImageURL = reply.groomImageURL?.absoluteString
    }
}
