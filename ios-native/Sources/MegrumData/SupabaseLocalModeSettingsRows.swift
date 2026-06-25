import Foundation

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
