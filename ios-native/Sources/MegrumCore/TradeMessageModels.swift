import Foundation

public enum TradeMessageType: String, Codable, Sendable, CaseIterable, Identifiable {
    case text
    case photo
    case outfitPhoto = "outfit_photo"
    case location
    case arrivalStatus = "arrival_status"
    case system

    public var id: String { rawValue }
}

public enum TradeArrivalStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case enroute
    case arrived
    case left

    public var id: String { rawValue }

    public var defaultBody: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }
}

public struct TradeMessage: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var senderID: UUID
    public var messageType: TradeMessageType
    public var body: String?
    public var photoURL: URL?
    public var locationLatitude: Double?
    public var locationLongitude: Double?
    public var locationLabel: String?
    public var meta: [String: String]
    public var createdAt: Date

    public init(
        id: UUID,
        proposalID: UUID,
        senderID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String] = [:],
        createdAt: Date = .now
    ) {
        self.id = id
        self.proposalID = proposalID
        self.senderID = senderID
        self.messageType = messageType
        self.body = body
        self.photoURL = photoURL
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationLabel = locationLabel
        self.meta = meta
        self.createdAt = createdAt
    }
}

public struct ProposalReadState: Identifiable, Codable, Hashable, Sendable {
    public var proposalID: UUID
    public var userID: UUID
    public var lastReadAt: Date
    public var updatedAt: Date?

    public var id: String {
        "\(proposalID.uuidString.lowercased())-\(userID.uuidString.lowercased())"
    }

    public init(
        proposalID: UUID,
        userID: UUID,
        lastReadAt: Date,
        updatedAt: Date? = nil
    ) {
        self.proposalID = proposalID
        self.userID = userID
        self.lastReadAt = lastReadAt
        self.updatedAt = updatedAt
    }
}

public struct TradeMessageCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var body: String

    public init(proposalID: UUID, body: String) {
        self.proposalID = proposalID
        self.body = body
    }
}

public struct TradePhotoMessageCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String
    public var messageType: TradeMessageType
    public var body: String?

    public init(
        proposalID: UUID,
        imageData: Data,
        imageContentType: String,
        messageType: TradeMessageType = .photo,
        body: String? = nil
    ) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.messageType = messageType
        self.body = body
    }
}
