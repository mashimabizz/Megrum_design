import Foundation

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
