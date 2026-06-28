import Foundation

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
    public var latestActivityAt: Date
    public var expiresAt: Date?
    public var replyCount: Int
    public var status: String
    public var anonymousDisplayName: String?
    public var anonymousAvatarID: String?

    public var thumbnailURL: URL? {
        imageURLs?.first
    }

    public var isClosed: Bool {
        status != "visible" || replyCount >= 1_000 || (expiresAt.map { $0 <= Date() } ?? false)
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
        createdAt: Date = .now,
        latestActivityAt: Date? = nil,
        expiresAt: Date? = nil,
        replyCount: Int = 0,
        status: String = "visible",
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil
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
        self.latestActivityAt = latestActivityAt ?? createdAt
        self.expiresAt = expiresAt
        self.replyCount = replyCount
        self.status = status
        self.anonymousDisplayName = anonymousDisplayName
        self.anonymousAvatarID = anonymousAvatarID
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
    public var anonymousDisplayName: String?
    public var anonymousAvatarID: String?

    public init(
        authorID: UUID,
        title: String,
        body: String,
        audience: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        imagePaths: [String] = [],
        thumbnailUpload: GoodsPhotoUpload? = nil,
        anonymousDisplayName: String? = nil,
        anonymousAvatarID: String? = nil
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
        self.anonymousDisplayName = anonymousDisplayName
        self.anonymousAvatarID = anonymousAvatarID
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
