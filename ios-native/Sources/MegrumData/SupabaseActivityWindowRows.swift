import Foundation

struct ActivityWindowRow: Decodable, Sendable {
    static let select = "id,user_id,venue,center_lat,center_lng,radius_m,event_name,eventless,start_at,end_at,note,status,created_at,updated_at"

    var id: UUID
    var userId: UUID
    var venue: String
    var centerLat: ActivityWindowFlexibleDouble?
    var centerLng: ActivityWindowFlexibleDouble?
    var radiusM: Int?
    var eventName: String?
    var eventless: Bool?
    var startAt: Date
    var endAt: Date
    var note: String?
    var status: SupabaseActivityWindowStatus
    var createdAt: Date?
    var updatedAt: Date?

    var activityWindow: SupabaseActivityWindow {
        let center = centerLat.flatMap { lat in
            centerLng.map { lng in
                SupabaseActivityWindowCoordinate(latitude: lat.value, longitude: lng.value)
            }
        }
        return SupabaseActivityWindow(
            id: id,
            userID: userId,
            venue: venue,
            center: center,
            radiusMeters: radiusM ?? 500,
            eventName: eventName,
            eventless: eventless ?? false,
            startAt: startAt,
            endAt: endAt,
            note: note,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct ActivityWindowCreatePayload: Encodable, Sendable {
    var userId: UUID
    var venue: String
    var centerLat: Double?
    var centerLng: Double?
    var radiusM: Int
    var eventName: String?
    var eventless: Bool
    var startAt: String
    var endAt: String
    var note: String?
    var status: String

    init(userID: UUID, input: SupabaseActivityWindowCreateInput, dateFormatter: ISO8601DateFormatter) {
        self.userId = userID
        self.venue = SupabaseTextNormalizer.trimmed(input.venue)
        self.centerLat = input.center?.latitude
        self.centerLng = input.center?.longitude
        self.radiusM = input.radiusMeters
        self.eventName = SupabaseTextNormalizer.optional(input.eventName)
        self.eventless = input.eventless
        self.startAt = dateFormatter.string(from: input.startAt)
        self.endAt = dateFormatter.string(from: input.endAt)
        self.note = SupabaseTextNormalizer.optional(input.note)
        self.status = input.status.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case venue
        case centerLat
        case centerLng
        case radiusM
        case eventName
        case eventless
        case startAt
        case endAt
        case note
        case status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(venue, forKey: .venue)
        try container.encodeIfPresent(centerLat, forKey: .centerLat)
        try container.encodeIfPresent(centerLng, forKey: .centerLng)
        try container.encode(radiusM, forKey: .radiusM)
        if let eventName {
            try container.encode(eventName, forKey: .eventName)
        } else {
            try container.encodeNil(forKey: .eventName)
        }
        try container.encode(eventless, forKey: .eventless)
        try container.encode(startAt, forKey: .startAt)
        try container.encode(endAt, forKey: .endAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(status, forKey: .status)
    }
}

struct ActivityWindowUpdatePayload: Encodable, Sendable {
    private var venue: String?
    private var centerLat: Double??
    private var centerLng: Double??
    private var radiusM: Int?
    private var eventName: String??
    private var eventless: Bool?
    private var startAt: String?
    private var endAt: String?
    private var note: String??
    private var status: String?

    init(input: SupabaseActivityWindowUpdateInput, dateFormatter: ISO8601DateFormatter) throws {
        if let venue = input.venue {
            let normalized = SupabaseTextNormalizer.trimmed(venue)
            guard !normalized.isEmpty, normalized.count <= 100 else {
                throw SupabaseActivityWindowClientError.invalidVenue
            }
            self.venue = normalized
        }
        if let center = input.center {
            guard (-90...90).contains(center.latitude),
                  (-180...180).contains(center.longitude)
            else {
                throw SupabaseActivityWindowClientError.invalidCoordinate
            }
            self.centerLat = .some(.some(center.latitude))
            self.centerLng = .some(.some(center.longitude))
        } else if input.clearsCenter {
            self.centerLat = .some(nil)
            self.centerLng = .some(nil)
        }
        if let radiusMeters = input.radiusMeters {
            guard (50...5_000).contains(radiusMeters) else {
                throw SupabaseActivityWindowClientError.invalidRadius
            }
            self.radiusM = radiusMeters
        }
        if let eventName = input.eventName {
            let normalized = SupabaseTextNormalizer.trimmed(eventName)
            guard normalized.count <= 100 else {
                throw SupabaseActivityWindowClientError.invalidEventName
            }
            self.eventName = .some(normalized.isEmpty ? nil : normalized)
        } else if input.clearsEventName {
            self.eventName = .some(nil)
        }
        self.eventless = input.eventless
        if let startAt = input.startAt {
            self.startAt = dateFormatter.string(from: startAt)
        }
        if let endAt = input.endAt {
            self.endAt = dateFormatter.string(from: endAt)
        }
        if let startAt = input.startAt, let endAt = input.endAt, startAt >= endAt {
            throw SupabaseActivityWindowClientError.invalidTimeRange
        }
        if let note = input.note {
            let normalized = SupabaseTextNormalizer.trimmed(note)
            guard normalized.count <= 200 else {
                throw SupabaseActivityWindowClientError.invalidNote
            }
            self.note = .some(normalized.isEmpty ? nil : normalized)
        } else if input.clearsNote {
            self.note = .some(nil)
        }
        self.status = input.status?.rawValue

        guard venue != nil
            || centerLat != nil
            || centerLng != nil
            || radiusM != nil
            || eventName != nil
            || eventless != nil
            || startAt != nil
            || endAt != nil
            || note != nil
            || status != nil
        else {
            throw SupabaseActivityWindowClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case venue
        case centerLat
        case centerLng
        case radiusM
        case eventName
        case eventless
        case startAt
        case endAt
        case note
        case status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(venue, forKey: .venue)
        if let centerLat {
            switch centerLat {
            case let .some(value):
                try container.encode(value, forKey: .centerLat)
            case .none:
                try container.encodeNil(forKey: .centerLat)
            }
        }
        if let centerLng {
            switch centerLng {
            case let .some(value):
                try container.encode(value, forKey: .centerLng)
            case .none:
                try container.encodeNil(forKey: .centerLng)
            }
        }
        try container.encodeIfPresent(radiusM, forKey: .radiusM)
        if let eventName {
            switch eventName {
            case let .some(value):
                try container.encode(value, forKey: .eventName)
            case .none:
                try container.encodeNil(forKey: .eventName)
            }
        }
        try container.encodeIfPresent(eventless, forKey: .eventless)
        try container.encodeIfPresent(startAt, forKey: .startAt)
        try container.encodeIfPresent(endAt, forKey: .endAt)
        if let note {
            switch note {
            case let .some(value):
                try container.encode(value, forKey: .note)
            case .none:
                try container.encodeNil(forKey: .note)
            }
        }
        try container.encodeIfPresent(status, forKey: .status)
    }
}

struct ActivityWindowStatusPayload: Encodable, Sendable {
    var status: SupabaseActivityWindowStatus
}

struct LocalModeSettingsRow: Decodable, Sendable {
    static let select = "user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"

    var userId: UUID
    var enabled: Bool?
    var awId: UUID?
    var radiusM: Int?
    var selectedCarryingIds: [UUID]?
    var selectedWishIds: [UUID]?
    var lastLat: ActivityWindowFlexibleDouble?
    var lastLng: ActivityWindowFlexibleDouble?
    var updatedAt: Date?

    var settings: SupabaseLocalModeSettings {
        let lastLocation = lastLat.flatMap { lat in
            lastLng.map { lng in
                SupabaseActivityWindowCoordinate(latitude: lat.value, longitude: lng.value)
            }
        }
        return SupabaseLocalModeSettings(
            userID: userId,
            enabled: enabled ?? false,
            activityWindowID: awId,
            radiusMeters: radiusM ?? 500,
            selectedCarryingIDs: selectedCarryingIds ?? [],
            selectedWishIDs: selectedWishIds ?? [],
            lastLocation: lastLocation,
            updatedAt: updatedAt
        )
    }
}

struct LocalModeSettingsUpsertPayload: Encodable, Sendable {
    private var userId: UUID
    private var enabled: Bool
    private var awId: UUID??
    private var radiusM: Int?
    private var selectedCarryingIds: [UUID]?
    private var selectedWishIds: [UUID]?
    private var lastLat: Double??
    private var lastLng: Double??

    init(userID: UUID, input: SupabaseLocalModeSettingsUpsertInput) throws {
        self.userId = userID
        self.enabled = input.enabled
        if let activityWindowID = input.activityWindowID {
            self.awId = .some(.some(activityWindowID))
        } else if input.clearsActivityWindowID {
            self.awId = .some(nil)
        }
        if let radiusMeters = input.radiusMeters {
            guard (50...5_000).contains(radiusMeters) else {
                throw SupabaseActivityWindowClientError.invalidRadius
            }
            self.radiusM = radiusMeters
        }
        self.selectedCarryingIds = Self.deduplicated(input.selectedCarryingIDs)
        self.selectedWishIds = Self.deduplicated(input.selectedWishIDs)
        if let lastLocation = input.lastLocation {
            guard (-90...90).contains(lastLocation.latitude),
                  (-180...180).contains(lastLocation.longitude)
            else {
                throw SupabaseActivityWindowClientError.invalidCoordinate
            }
            self.lastLat = .some(.some(lastLocation.latitude))
            self.lastLng = .some(.some(lastLocation.longitude))
        } else if input.clearsLastLocation {
            self.lastLat = .some(nil)
            self.lastLng = .some(nil)
        }
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case enabled
        case awId
        case radiusM
        case selectedCarryingIds
        case selectedWishIds
        case lastLat
        case lastLng
    }

    private static func deduplicated(_ ids: [UUID]?) -> [UUID]? {
        guard let ids else {
            return nil
        }
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(enabled, forKey: .enabled)
        if let awId {
            switch awId {
            case let .some(value):
                try container.encode(value, forKey: .awId)
            case .none:
                try container.encodeNil(forKey: .awId)
            }
        }
        try container.encodeIfPresent(radiusM, forKey: .radiusM)
        try container.encodeIfPresent(selectedCarryingIds, forKey: .selectedCarryingIds)
        try container.encodeIfPresent(selectedWishIds, forKey: .selectedWishIds)
        if let lastLat {
            switch lastLat {
            case let .some(value):
                try container.encode(value, forKey: .lastLat)
            case .none:
                try container.encodeNil(forKey: .lastLat)
            }
        }
        if let lastLng {
            switch lastLng {
            case let .some(value):
                try container.encode(value, forKey: .lastLng)
            case .none:
                try container.encodeNil(forKey: .lastLng)
            }
        }
    }
}

struct ActivityWindowFlexibleDouble: Decodable, Sendable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self.value = value
            return
        }
        let rawValue = try container.decode(String.self)
        guard let value = Double(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a Double-compatible value"
            )
        }
        self.value = value
    }
}
