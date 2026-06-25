import Foundation

public struct SupabaseHomeLocalModeRow: Decodable, Equatable, Sendable {
    public var userId: UUID?
    public var enabled: Bool?
    public var awId: UUID?
    public var radiusM: Int?
    public var selectedCarryingIds: [UUID]?
    public var selectedWishIds: [UUID]?
    public var lastLat: Double?
    public var lastLng: Double?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case userId
        case enabled
        case awId
        case radiusM
        case selectedCarryingIds
        case selectedWishIds
        case lastLat
        case lastLng
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.awId = try container.decodeIfPresent(UUID.self, forKey: .awId)
        self.radiusM = try container.decodeIfPresent(Int.self, forKey: .radiusM)
        self.selectedCarryingIds = try container.decodeIfPresent([UUID].self, forKey: .selectedCarryingIds)
        self.selectedWishIds = try container.decodeIfPresent([UUID].self, forKey: .selectedWishIds)
        self.lastLat = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .lastLat)?.value
        self.lastLng = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .lastLng)?.value
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeActivityWindowRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var venue: String?
    public var startAt: Date
    public var endAt: Date
    public var radiusM: Int?
    public var centerLat: Double?
    public var centerLng: Double?
    public var status: String?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case venue
        case startAt
        case endAt
        case radiusM
        case centerLat
        case centerLng
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.venue = try container.decodeIfPresent(String.self, forKey: .venue)
        self.startAt = try container.decode(Date.self, forKey: .startAt)
        self.endAt = try container.decode(Date.self, forKey: .endAt)
        self.radiusM = try container.decodeIfPresent(Int.self, forKey: .radiusM)
        self.centerLat = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .centerLat)?.value
        self.centerLng = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .centerLng)?.value
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }
}

extension SupabaseHomeLocalModeRow {
    static let select = "user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"
}

extension SupabaseHomeActivityWindowRow {
    static let select = "id,user_id,venue,start_at,end_at,radius_m,center_lat,center_lng,status"
}
