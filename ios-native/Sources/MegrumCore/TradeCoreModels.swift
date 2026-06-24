import Foundation

public struct TradeEvidencePhoto: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var photoURL: URL
    public var position: Int
    public var takenAt: Date?
    public var takenBy: UUID

    public init(
        id: UUID,
        proposalID: UUID,
        photoURL: URL,
        position: Int,
        takenAt: Date? = nil,
        takenBy: UUID
    ) {
        self.id = id
        self.proposalID = proposalID
        self.photoURL = photoURL
        self.position = max(1, position)
        self.takenAt = takenAt
        self.takenBy = takenBy
    }

    public func isUploadedBy(_ userID: UUID?) -> Bool {
        takenBy == userID
    }
}

public struct PersonalSchedule: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        id: UUID,
        userID: UUID,
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var durationInterval: DateInterval {
        if endAt > startAt {
            return DateInterval(start: startAt, end: endAt)
        }
        return DateInterval(start: startAt, duration: 60)
    }

    public func overlaps(start: Date, end: Date) -> Bool {
        startAt < end && endAt > start
    }
}

public struct PersonalScheduleCreateInput: Equatable, Sendable {
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var normalizedPlaceName: String? {
        placeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var normalizedNote: String? {
        note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var isValid: Bool {
        !normalizedTitle.isEmpty && startAt < endAt
    }
}

public struct TradeEvidenceCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String

    public init(proposalID: UUID, imageData: Data, imageContentType: String) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
    }
}

public struct TradeEvaluationCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var stars: Int
    public var comment: String?

    public init(proposalID: UUID, stars: Int, comment: String? = nil) {
        self.proposalID = proposalID
        self.stars = stars
        self.comment = comment
    }
}

public enum TradeDisputeCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case short
    case wrong
    case noshow
    case cancel
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .short:
            "受け取った点数が少ない"
        case .wrong:
            "グッズが違う・状態が悪い"
        case .noshow:
            "相手が現れなかった"
        case .cancel:
            "合意済みのキャンセル"
        case .other:
            "その他"
        }
    }
}

public struct TradeDisputeCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var category: TradeDisputeCategory
    public var factMemo: String

    public init(proposalID: UUID, category: TradeDisputeCategory, factMemo: String) {
        self.proposalID = proposalID
        self.category = category
        self.factMemo = factMemo
    }
}

public struct TradeDisputeTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var ticketNo: String
    public var status: String
    public var submittedAt: Date

    public init(
        id: UUID,
        proposalID: UUID,
        ticketNo: String,
        status: String,
        submittedAt: Date = .now
    ) {
        self.id = id
        self.proposalID = proposalID
        self.ticketNo = ticketNo
        self.status = status
        self.submittedAt = submittedAt
    }
}

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
