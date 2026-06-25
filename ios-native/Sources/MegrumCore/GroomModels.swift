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
