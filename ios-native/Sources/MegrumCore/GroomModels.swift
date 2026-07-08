import Foundation

public struct GroomPost: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var authorID: UUID
    public var imageURL: URL
    public var latitude: Double
    public var longitude: Double
    public var groupID: UUID?
    public var characterID: UUID?
    public var seriesName: String?
    public var createdAt: Date
    public var expiresAt: Date?
    public var likeCount: Int
    public var liked: Bool
    /// FB(iter1226.390): 自分の1km圏内で自分の推しに一致して「遭遇済み」か。
    /// 圏外でもプレミアムなら閲覧可の判定に使う（通知の有無に関わらない）。
    public var encounteredInRange: Bool

    public init(
        id: UUID,
        authorID: UUID,
        imageURL: URL,
        latitude: Double,
        longitude: Double,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        seriesName: String? = nil,
        createdAt: Date = .now,
        expiresAt: Date? = nil,
        likeCount: Int = 0,
        liked: Bool = false,
        encounteredInRange: Bool = false
    ) {
        self.id = id
        self.authorID = authorID
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.groupID = groupID
        self.characterID = characterID
        self.seriesName = seriesName
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.likeCount = likeCount
        self.liked = liked
        self.encounteredInRange = encounteredInRange
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
    public var groupID: UUID?
    public var characterID: UUID?
    public var seriesName: String?

    public init(
        authorID: UUID,
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeHint: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        seriesName: String? = nil
    ) {
        self.authorID = authorID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.caption = caption
        self.latitude = latitude
        self.longitude = longitude
        self.placeHint = placeHint
        self.groupID = groupID
        self.characterID = characterID
        self.seriesName = seriesName
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

public enum GroomReportReason: String, Codable, Sendable, CaseIterable, Identifiable {
    case spam
    case harassment
    case privacy
    case other

    public var id: String { rawValue }
}

public struct GroomReportCreateInput: Equatable, Sendable {
    public var groomPostID: UUID
    public var reportedUserID: UUID
    public var reason: GroomReportReason
    public var note: String?

    public init(
        groomPostID: UUID,
        reportedUserID: UUID,
        reason: GroomReportReason,
        note: String? = nil
    ) {
        self.groomPostID = groomPostID
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.note = note
    }
}

public struct GroomReportTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var groomPostID: UUID
    public var reportedUserID: UUID
    public var reason: GroomReportReason
    public var status: String
    public var createdAt: Date

    public init(
        id: UUID,
        groomPostID: UUID,
        reportedUserID: UUID,
        reason: GroomReportReason,
        status: String = "open",
        createdAt: Date = .now
    ) {
        self.id = id
        self.groomPostID = groomPostID
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
    }
}
