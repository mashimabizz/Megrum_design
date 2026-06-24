import Foundation

public struct GroomPost: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var authorID: UUID
    public var imageURL: URL
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var liked: Bool

    public init(
        id: UUID,
        authorID: UUID,
        imageURL: URL,
        latitude: Double,
        longitude: Double,
        createdAt: Date = .now,
        liked: Bool = false
    ) {
        self.id = id
        self.authorID = authorID
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.liked = liked
    }
}

public struct GroomPostCreateInput: Equatable, Sendable {
    public var authorID: UUID
    public var imageData: Data
    public var imageContentType: String
    public var caption: String?
    public var latitude: Double?
    public var longitude: Double?
    public var placeHint: String?

    public init(
        authorID: UUID,
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeHint: String? = nil
    ) {
        self.authorID = authorID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.caption = caption
        self.latitude = latitude
        self.longitude = longitude
        self.placeHint = placeHint
    }
}

public struct GroomReply: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var groomPostID: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var body: String
    public var groomImageURL: URL?
    public var readAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        groomPostID: UUID,
        senderID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.groomPostID = groomPostID
        self.senderID = senderID
        self.recipientID = recipientID
        self.body = body
        self.groomImageURL = groomImageURL
        self.readAt = readAt
        self.createdAt = createdAt
    }
}

public struct GroomReplyCreateInput: Equatable, Sendable {
    public var groomPostID: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var body: String
    public var groomImageURL: URL?

    public init(
        groomPostID: UUID,
        senderID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL? = nil
    ) {
        self.groomPostID = groomPostID
        self.senderID = senderID
        self.recipientID = recipientID
        self.body = body
        self.groomImageURL = groomImageURL
    }
}

public struct GroomReaction: Identifiable, Codable, Hashable, Sendable {
    public var groomPostID: UUID
    public var userID: UUID
    public var reactionType: String
    public var createdAt: Date

    public var id: String {
        [
            groomPostID.uuidString.lowercased(),
            userID.uuidString.lowercased(),
            reactionType
        ].joined(separator: "-")
    }

    public init(
        groomPostID: UUID,
        userID: UUID,
        reactionType: String = "like",
        createdAt: Date = .now
    ) {
        self.groomPostID = groomPostID
        self.userID = userID
        self.reactionType = reactionType
        self.createdAt = createdAt
    }
}

public enum MeguriMessageType: String, Codable, Sendable {
    case text
    case image
}

public struct MeguriMessage: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var sourceGroomReplyID: UUID?
    public var messageType: MeguriMessageType
    public var body: String?
    public var imageURL: URL?
    public var imagePath: String?
    public var readAt: Date?
    public var createdAt: Date
    public var locked: Bool
    public var senderDisplayName: String?
    public var senderHandle: String?
    public var recipientDisplayName: String?
    public var recipientHandle: String?

    public init(
        id: UUID,
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        messageType: MeguriMessageType = .text,
        body: String? = nil,
        imageURL: URL? = nil,
        imagePath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now,
        locked: Bool = false,
        senderDisplayName: String? = nil,
        senderHandle: String? = nil,
        recipientDisplayName: String? = nil,
        recipientHandle: String? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.recipientID = recipientID
        self.sourceGroomReplyID = sourceGroomReplyID
        self.messageType = messageType
        self.body = body
        self.imageURL = imageURL
        self.imagePath = imagePath
        self.readAt = readAt
        self.createdAt = createdAt
        self.locked = locked
        self.senderDisplayName = senderDisplayName
        self.senderHandle = senderHandle
        self.recipientDisplayName = recipientDisplayName
        self.recipientHandle = recipientHandle
    }
}

public struct MeguriMessageCreateInput: Equatable, Sendable {
    public var senderID: UUID
    public var recipientID: UUID
    public var sourceGroomReplyID: UUID?
    public var body: String

    public init(
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        body: String
    ) {
        self.senderID = senderID
        self.recipientID = recipientID
        self.sourceGroomReplyID = sourceGroomReplyID
        self.body = body
    }
}

public struct BoardThread: Identifiable, Codable, Hashable, Sendable {
    public enum Audience: String, Codable, Sendable, CaseIterable, Identifiable {
        case nearby3km = "nearby_3km"
        case samePrefecture = "same_prefecture"
        case sameSpot = "same_spot"
        case global

        public var id: String { rawValue }
    }

    public var id: UUID
    public var authorID: UUID
    public var title: String
    public var body: String
    public var audience: Audience
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?
    public var imageURLs: [URL]?
    public var imagePaths: [String]?
    public var createdAt: Date

    public var thumbnailURL: URL? {
        imageURLs?.first
    }

    public init(
        id: UUID,
        authorID: UUID,
        title: String,
        body: String,
        audience: Audience,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        imageURLs: [URL] = [],
        imagePaths: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.authorID = authorID
        self.title = title
        self.body = body
        self.audience = audience
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
        self.imageURLs = imageURLs.isEmpty ? nil : imageURLs
        self.imagePaths = imagePaths.isEmpty ? nil : imagePaths
        self.createdAt = createdAt
    }
}

public struct BoardThreadCreateInput: Equatable, Sendable {
    public var authorID: UUID
    public var title: String
    public var body: String
    public var audience: BoardThread.Audience
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?
    public var imagePaths: [String]
    public var thumbnailUpload: GoodsPhotoUpload?

    public init(
        authorID: UUID,
        title: String,
        body: String,
        audience: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        imagePaths: [String] = [],
        thumbnailUpload: GoodsPhotoUpload? = nil
    ) {
        self.authorID = authorID
        self.title = title
        self.body = body
        self.audience = audience
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
        self.imagePaths = imagePaths
        self.thumbnailUpload = thumbnailUpload
    }
}

public struct BoardReply: Identifiable, Codable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable, CaseIterable, Identifiable {
        case visible
        case deleted

        public var id: String { rawValue }
    }

    public var id: UUID
    public var threadID: UUID
    public var authorID: UUID
    public var body: String
    public var status: Status
    public var createdAt: Date

    public init(
        id: UUID,
        threadID: UUID,
        authorID: UUID,
        body: String,
        status: Status = .visible,
        createdAt: Date = .now
    ) {
        self.id = id
        self.threadID = threadID
        self.authorID = authorID
        self.body = body
        self.status = status
        self.createdAt = createdAt
    }
}

public struct BoardReplyCreateInput: Equatable, Sendable {
    public var threadID: UUID
    public var body: String
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?
    public var scope: BoardThread.Audience

    public init(
        threadID: UUID,
        body: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) {
        self.threadID = threadID
        self.body = body
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
        self.scope = scope
    }
}
