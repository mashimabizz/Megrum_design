import Foundation

public enum SupabaseActivityWindowClientError: Error, Equatable, Sendable {
    case invalidVenue
    case invalidTimeRange
    case invalidRadius
    case invalidCoordinate
    case invalidEventName
    case invalidNote
    case emptyUpdate
    case malformedResponse
}

public enum SupabaseActivityWindowStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case enabled
    case disabled
    case archived

    public var id: String { rawValue }
}

public struct SupabaseActivityWindowCoordinate: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct SupabaseActivityWindow: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var venue: String
    public var center: SupabaseActivityWindowCoordinate?
    public var radiusMeters: Int
    public var eventName: String?
    public var eventless: Bool
    public var startAt: Date
    public var endAt: Date
    public var note: String?
    public var status: SupabaseActivityWindowStatus
    public var createdAt: Date?
    public var updatedAt: Date?
}

public struct SupabaseActivityWindowCreateInput: Equatable, Sendable {
    public var venue: String
    public var center: SupabaseActivityWindowCoordinate?
    public var radiusMeters: Int
    public var eventName: String?
    public var eventless: Bool
    public var startAt: Date
    public var endAt: Date
    public var note: String?
    public var status: SupabaseActivityWindowStatus

    public init(
        venue: String,
        center: SupabaseActivityWindowCoordinate? = nil,
        radiusMeters: Int = 500,
        eventName: String? = nil,
        eventless: Bool = true,
        startAt: Date,
        endAt: Date,
        note: String? = nil,
        status: SupabaseActivityWindowStatus = .enabled
    ) {
        self.venue = venue
        self.center = center
        self.radiusMeters = radiusMeters
        self.eventName = eventName
        self.eventless = eventless
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
        self.status = status
    }
}

public struct SupabaseActivityWindowUpdateInput: Equatable, Sendable {
    public var venue: String?
    public var center: SupabaseActivityWindowCoordinate?
    public var clearsCenter: Bool
    public var radiusMeters: Int?
    public var eventName: String?
    public var clearsEventName: Bool
    public var eventless: Bool?
    public var startAt: Date?
    public var endAt: Date?
    public var note: String?
    public var clearsNote: Bool
    public var status: SupabaseActivityWindowStatus?

    public init(
        venue: String? = nil,
        center: SupabaseActivityWindowCoordinate? = nil,
        clearsCenter: Bool = false,
        radiusMeters: Int? = nil,
        eventName: String? = nil,
        clearsEventName: Bool = false,
        eventless: Bool? = nil,
        startAt: Date? = nil,
        endAt: Date? = nil,
        note: String? = nil,
        clearsNote: Bool = false,
        status: SupabaseActivityWindowStatus? = nil
    ) {
        self.venue = venue
        self.center = center
        self.clearsCenter = clearsCenter
        self.radiusMeters = radiusMeters
        self.eventName = eventName
        self.clearsEventName = clearsEventName
        self.eventless = eventless
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
        self.clearsNote = clearsNote
        self.status = status
    }
}

public struct SupabaseLocalModeSettings: Equatable, Sendable {
    public var userID: UUID
    public var enabled: Bool
    public var activityWindowID: UUID?
    public var radiusMeters: Int
    public var selectedCarryingIDs: [UUID]
    public var selectedWishIDs: [UUID]
    public var lastLocation: SupabaseActivityWindowCoordinate?
    public var updatedAt: Date?
}

public struct SupabaseLocalModeSettingsUpsertInput: Equatable, Sendable {
    public var enabled: Bool
    public var activityWindowID: UUID?
    public var clearsActivityWindowID: Bool
    public var radiusMeters: Int?
    public var selectedCarryingIDs: [UUID]?
    public var selectedWishIDs: [UUID]?
    public var lastLocation: SupabaseActivityWindowCoordinate?
    public var clearsLastLocation: Bool

    public init(
        enabled: Bool,
        activityWindowID: UUID? = nil,
        clearsActivityWindowID: Bool = false,
        radiusMeters: Int? = nil,
        selectedCarryingIDs: [UUID]? = nil,
        selectedWishIDs: [UUID]? = nil,
        lastLocation: SupabaseActivityWindowCoordinate? = nil,
        clearsLastLocation: Bool = false
    ) {
        self.enabled = enabled
        self.activityWindowID = activityWindowID
        self.clearsActivityWindowID = clearsActivityWindowID
        self.radiusMeters = radiusMeters
        self.selectedCarryingIDs = selectedCarryingIDs
        self.selectedWishIDs = selectedWishIDs
        self.lastLocation = lastLocation
        self.clearsLastLocation = clearsLastLocation
    }
}
