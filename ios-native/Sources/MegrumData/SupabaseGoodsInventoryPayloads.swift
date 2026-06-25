import Foundation
import MegrumCore

struct GoodsEntryPayload: Encodable, Sendable {
    var userId: UUID
    var kind: String
    var groupId: UUID
    var characterId: UUID?
    var goodsTypeId: UUID
    var title: String
    var condition: String?
    var priority: String?
    var flexLevel: String?
    var exchangeType: String
    var quantity: Int
    var status: String?
    var photoUrls: [String]

    init(userID: UUID, input: GoodsEntryInput, photoURLs: [String] = []) {
        self.userId = userID
        self.kind = input.kind.inventoryKind
        self.groupId = input.groupID
        self.characterId = input.memberID
        self.goodsTypeId = input.goodsTypeID
        self.title = SupabaseTextNormalizer.trimmed(input.title)
        self.condition = input.kind == .inventory ? "good" : nil
        self.priority = input.kind == .wish ? "second" : nil
        self.flexLevel = nil
        self.exchangeType = "any"
        self.quantity = max(1, min(input.quantity, 999))
        self.status = input.status?.rawValue
        self.photoUrls = photoURLs
    }
}

struct AttachInventoryTagPayload: Encodable, Sendable {
    var inventoryID: UUID
    var rawLabel: String

    init(inventoryID: UUID, rawLabel: String) {
        self.inventoryID = inventoryID
        self.rawLabel = rawLabel
    }

    enum CodingKeys: String, CodingKey {
        case inventoryID = "p_inventory_id"
        case rawLabel = "p_raw_label"
    }
}

struct DetachInventoryTagPayload: Encodable, Sendable {
    var inventoryID: UUID
    var tagID: UUID

    init(inventoryID: UUID, tagID: UUID) {
        self.inventoryID = inventoryID
        self.tagID = tagID
    }

    enum CodingKeys: String, CodingKey {
        case inventoryID = "p_inventory_id"
        case tagID = "p_tag_id"
    }
}

struct GoodsInventoryStatusPayload: Encodable, Sendable {
    var status: String
}

struct GoodsInventoryUpdatePayload: Encodable, Sendable {
    private var title: String?
    private var groupId: UUID?
    private var characterId: UUID??
    private var goodsTypeId: UUID?
    private var quantity: Int?
    private var status: String?
    private var photoUrls: [String]?

    init(input: GoodsInventoryUpdateInput) throws {
        if let title = input.title {
            let normalized = SupabaseTextNormalizer.trimmed(title)
            guard !normalized.isEmpty else {
                throw SupabaseGoodsInventoryClientError.emptyTitle
            }
            self.title = normalized
        }
        if let quantity = input.quantity {
            guard (1...999).contains(quantity) else {
                throw SupabaseGoodsInventoryClientError.invalidQuantity
            }
            self.quantity = quantity
        }

        self.groupId = input.groupID
        self.goodsTypeId = input.goodsTypeID
        self.status = input.status?.rawValue
        self.photoUrls = input.photoURLs.map(SupabaseTextNormalizer.nonEmptyValues)

        if let characterID = input.characterID {
            self.characterId = .some(.some(characterID))
        } else if input.clearsCharacterID {
            self.characterId = .some(nil)
        }

        guard title != nil
            || groupId != nil
            || characterId != nil
            || goodsTypeId != nil
            || quantity != nil
            || status != nil
            || photoUrls != nil
        else {
            throw SupabaseGoodsInventoryClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case title
        case groupId
        case characterId
        case goodsTypeId
        case quantity
        case status
        case photoUrls
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        if let characterId {
            switch characterId {
            case let .some(id):
                try container.encode(id, forKey: .characterId)
            case .none:
                try container.encodeNil(forKey: .characterId)
            }
        }
        try container.encodeIfPresent(goodsTypeId, forKey: .goodsTypeId)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(photoUrls, forKey: .photoUrls)
    }
}
