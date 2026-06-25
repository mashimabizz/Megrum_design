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

struct GroomReactionPayload: Encodable, Sendable {
    var groomPostID: UUID
    var userID: UUID
    var reactionType = "like"
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
