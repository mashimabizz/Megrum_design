import Foundation

public struct SupabaseHomeComposition: Equatable, Sendable {
    public var localMode: SupabaseHomeLocalModeRow?
    public var viewerUser: SupabaseHomeUserRow?
    public var viewerInventory: [SupabaseHomeGoodsRow]
    public var viewerWishes: [SupabaseHomeGoodsRow]
    public var viewerListings: [SupabaseHomeListingRow]
    public var partnerInventory: [SupabaseHomeGoodsRow]
    public var partnerWishes: [SupabaseHomeGoodsRow]
    public var partnerUsers: [SupabaseHomeUserRow]
    public var partnerListings: [SupabaseHomeListingRow]
    public var listingWishOptions: [SupabaseHomeListingWishOptionRow]
    public var viewerActivityWindows: [SupabaseHomeActivityWindowRow]
    public var partnerActivityWindows: [SupabaseHomeActivityWindowRow]
    public var inventoryTags: [SupabaseHomeInventoryTagRow]
    public var unreadNotificationIDs: [UUID]

    public init(
        localMode: SupabaseHomeLocalModeRow?,
        viewerUser: SupabaseHomeUserRow? = nil,
        viewerInventory: [SupabaseHomeGoodsRow],
        viewerWishes: [SupabaseHomeGoodsRow],
        viewerListings: [SupabaseHomeListingRow],
        partnerInventory: [SupabaseHomeGoodsRow],
        partnerWishes: [SupabaseHomeGoodsRow],
        partnerUsers: [SupabaseHomeUserRow],
        partnerListings: [SupabaseHomeListingRow],
        listingWishOptions: [SupabaseHomeListingWishOptionRow],
        viewerActivityWindows: [SupabaseHomeActivityWindowRow],
        partnerActivityWindows: [SupabaseHomeActivityWindowRow],
        inventoryTags: [SupabaseHomeInventoryTagRow],
        unreadNotificationIDs: [UUID]
    ) {
        self.localMode = localMode
        self.viewerUser = viewerUser
        self.viewerInventory = viewerInventory
        self.viewerWishes = viewerWishes
        self.viewerListings = viewerListings
        self.partnerInventory = partnerInventory
        self.partnerWishes = partnerWishes
        self.partnerUsers = partnerUsers
        self.partnerListings = partnerListings
        self.listingWishOptions = listingWishOptions
        self.viewerActivityWindows = viewerActivityWindows
        self.partnerActivityWindows = partnerActivityWindows
        self.inventoryTags = inventoryTags
        self.unreadNotificationIDs = unreadNotificationIDs
    }

    public var unreadNotificationCount: Int {
        unreadNotificationIDs.count
    }
}

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

public struct SupabaseHomeGoodsRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var kind: String?
    public var groupId: UUID?
    public var characterId: UUID?
    public var characterRequestId: UUID?
    public var goodsTypeId: UUID?
    public var title: String
    public var photoUrls: [String]
    public var quantity: Int?
    public var lockedQty: Int?
    public var marketAvailableQty: Int?
    public var exchangeType: String?
    public var hue: String?
    public var status: String?
    public var groupName: String?
    public var characterName: String?
    public var goodsTypeName: String?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case kind
        case groupId
        case characterId
        case characterRequestId
        case goodsTypeId
        case title
        case photoUrls
        case quantity
        case lockedQty
        case marketAvailableQty
        case exchangeType
        case hue
        case status
        case group
        case character
        case goodsType
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        self.characterId = try container.decodeIfPresent(UUID.self, forKey: .characterId)
        self.characterRequestId = try container.decodeIfPresent(UUID.self, forKey: .characterRequestId)
        self.goodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .goodsTypeId)
        self.title = try container.decode(String.self, forKey: .title)
        self.photoUrls = try container.decodeIfPresent([String].self, forKey: .photoUrls) ?? []
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        self.lockedQty = try container.decodeIfPresent(Int.self, forKey: .lockedQty)
        self.marketAvailableQty = try container.decodeIfPresent(Int.self, forKey: .marketAvailableQty)
        self.exchangeType = try container.decodeIfPresent(String.self, forKey: .exchangeType)
        self.hue = try container.decodeIfPresent(SupabaseHomeFlexibleString.self, forKey: .hue)?.value
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.groupName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .group)?.name
        self.characterName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .character)?.name
        self.goodsTypeName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .goodsType)?.name
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeUserRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var handle: String?
    public var displayName: String?
    public var primaryArea: String?
    public var avatarUrl: String?
    public var gender: String?
    public var age: Int?
    public var paymentMethods: [String]
    public var paymentNote: String?
    public var isTestAccount: Bool?
    public var averageStars: Double?
    public var evaluationCount: Int?
    public var completedTradeCount: Int?

    enum CodingKeys: CodingKey {
        case id
        case handle
        case displayName
        case primaryArea
        case avatarUrl
        case gender
        case age
        case paymentMethods
        case paymentNote
        case isTestAccount
        case averageStars
        case evaluationCount
        case completedTradeCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.handle = try container.decodeIfPresent(String.self, forKey: .handle)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.primaryArea = try container.decodeIfPresent(String.self, forKey: .primaryArea)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.age = try container.decodeIfPresent(Int.self, forKey: .age)
        self.paymentMethods = try container.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
        self.paymentNote = try container.decodeIfPresent(String.self, forKey: .paymentNote)
        self.isTestAccount = try container.decodeIfPresent(Bool.self, forKey: .isTestAccount)
        self.averageStars = try container.decodeIfPresent(Double.self, forKey: .averageStars)
        self.evaluationCount = try container.decodeIfPresent(Int.self, forKey: .evaluationCount)
        self.completedTradeCount = try container.decodeIfPresent(Int.self, forKey: .completedTradeCount)
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

public struct SupabaseHomeInventoryTagRow: Decodable, Equatable, Sendable {
    public var inventoryId: UUID
    public var tagId: UUID
    public var label: String?

    enum CodingKeys: CodingKey {
        case inventoryId
        case tagId
        case tag
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inventoryId = try container.decode(UUID.self, forKey: .inventoryId)
        self.tagId = try container.decode(UUID.self, forKey: .tagId)
        self.label = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .tag)?.name
    }
}

public struct SupabaseHomeNotificationIDRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
}

extension SupabaseHomeLocalModeRow {
    static let select = "user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"
}

extension SupabaseHomeGoodsRow {
    static let select = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,locked_qty,market_available_qty,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
    static let legacySelect = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
}

extension SupabaseHomeUserRow {
    static let select = "id,handle,display_name,primary_area,avatar_url,gender,age,payment_methods,payment_note,is_test_account"
    static let legacySelect = "id,handle,display_name,primary_area,avatar_url,gender"
}

extension SupabaseHomeActivityWindowRow {
    static let select = "id,user_id,venue,start_at,end_at,radius_m,center_lat,center_lng,status"
}

extension SupabaseHomeInventoryTagRow {
    static let select = "inventory_id,tag_id,tag:tags_master(label)"
}

extension SupabaseHomeNotificationIDRow {
    static let select = "id"
}

private struct SupabaseHomeRelation: Decodable, Equatable, Sendable {
    var name: String?

    enum CodingKeys: CodingKey {
        case name
        case label
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
                ?? container.decodeIfPresent(String.self, forKey: .label)
            return
        }
        if var unkeyed = try? decoder.unkeyedContainer() {
            self = try unkeyed.decodeIfPresent(SupabaseHomeRelation.self) ?? SupabaseHomeRelation(name: nil)
            return
        }
        self.name = nil
    }

    init(name: String?) {
        self.name = name
    }
}

private struct SupabaseHomeFlexibleDouble: Decodable, Equatable, Sendable {
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

private struct SupabaseHomeFlexibleString: Decodable, Equatable, Sendable {
    var value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
            return
        }
        if let value = try? container.decode(Int.self) {
            self.value = "\(value)"
            return
        }
        let value = try container.decode(Double.self)
        self.value = "\(value)"
    }
}

extension UUID {
    var lowercaseString: String {
        uuidString.lowercased()
    }
}

extension Array where Element == UUID {
    func uniqueLowercaseStrings() -> [String] {
        var seen = Set<UUID>()
        return filter { seen.insert($0).inserted }.map(\.lowercaseString)
    }
}
