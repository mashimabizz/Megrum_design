import Foundation
import MegrumCore

struct GoodsTypeRow: Decodable, Sendable {
    static let select = "id,name,category,display_order"

    var id: UUID
    var name: String
    var category: String?
    var displayOrder: Int?

    var goodsType: GoodsType {
        GoodsType(
            id: id,
            name: name,
            category: category,
            displayOrder: displayOrder ?? 0
        )
    }
}

struct GoodsInventoryRow: Decodable, Sendable {
    static let select = "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity,exchange_type,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name)"
    static let legacySelect = select

    var id: UUID
    var userId: UUID
    var kind: String?
    var status: String?
    var groupId: UUID?
    var characterId: UUID?
    var goodsTypeId: UUID?
    var title: String
    var photoUrls: [String]?
    var quantity: Int?
    var lockedQty: Int?
    var marketAvailableQty: Int?
    var exchangeType: String?
    var groupName: String?
    var characterName: String?
    var goodsTypeName: String?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case kind
        case status
        case groupId
        case characterId
        case goodsTypeId
        case title
        case photoUrls
        case quantity
        case lockedQty
        case marketAvailableQty
        case exchangeType
        case group
        case character
        case goodsType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        self.characterId = try container.decodeIfPresent(UUID.self, forKey: .characterId)
        self.goodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .goodsTypeId)
        self.title = try container.decode(String.self, forKey: .title)
        self.photoUrls = try container.decodeIfPresent([String].self, forKey: .photoUrls)
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        self.lockedQty = try container.decodeIfPresent(Int.self, forKey: .lockedQty)
        self.marketAvailableQty = try container.decodeIfPresent(Int.self, forKey: .marketAvailableQty)
        self.exchangeType = try container.decodeIfPresent(String.self, forKey: .exchangeType)
        self.groupName = try container.decodeIfPresent(GoodsInventoryRelationRow.self, forKey: .group)?.name
        self.characterName = try container.decodeIfPresent(GoodsInventoryRelationRow.self, forKey: .character)?.name
        self.goodsTypeName = try container.decodeIfPresent(GoodsInventoryRelationRow.self, forKey: .goodsType)?.name
    }

    var goodsItem: GoodsItem {
        GoodsItem(
            id: id,
            ownerID: userId,
            kind: GoodsEntryKind(inventoryKind: kind),
            status: status.flatMap(GoodsEntryStatus.init(rawValue:)),
            groupID: groupId,
            memberID: characterId,
            goodsTypeID: goodsTypeId,
            groupName: groupName,
            memberName: characterName,
            goodsTypeName: goodsTypeName,
            title: masterGoodsTitle ?? title,
            imageURL: photoUrls?.compactMap(URL.init(string:)).first,
            tags: [],
            quantity: max(1, quantity ?? 1),
            lockedQuantity: max(0, lockedQty ?? 0),
            marketAvailableQuantity: marketAvailableQty.map { max(0, $0) },
            exchangeMethod: ExchangeMethod(exchangeTypeValue: exchangeType)
        )
    }

    private var masterGoodsTitle: String? {
        let names = [
            characterId == nil ? normalizedMasterName(groupName) : normalizedMasterName(characterName),
            normalizedMasterName(goodsTypeName)
        ].compactMap { $0 }
        return names.isEmpty ? nil : names.joined(separator: " ")
    }

    private func normalizedMasterName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct GoodsInventoryRelationRow: Decodable, Sendable {
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
            self = try unkeyed.decodeIfPresent(GoodsInventoryRelationRow.self) ?? GoodsInventoryRelationRow(name: nil)
            return
        }
        self.name = nil
    }

    init(name: String?) {
        self.name = name
    }
}

struct GoodsInventoryTagRow: Decodable, Sendable {
    static let select = "inventory_id,tag:tags_master(id,label)"

    var inventoryId: UUID
    var tag: GoodsTagRow?
}

struct GoodsTagRow: Decodable, Sendable {
    var id: UUID
    var label: String

    var goodsTag: GoodsTag {
        GoodsTag(id: id, name: label)
    }
}
