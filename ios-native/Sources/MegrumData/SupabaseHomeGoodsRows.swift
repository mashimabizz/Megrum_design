import Foundation

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

extension SupabaseHomeGoodsRow {
    static let select = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,locked_qty,market_available_qty,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
    static let legacySelect = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
}

extension SupabaseHomeInventoryTagRow {
    static let select = "inventory_id,tag_id,tag:tags_master(label)"
}
