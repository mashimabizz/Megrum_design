import Foundation
import MegrumCore

struct GoodsInventoryRow: Decodable, Sendable {
    static let select = "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity,locked_qty,market_available_qty"
    static let legacySelect = "id,user_id,kind,status,group_id,character_id,goods_type_id,title,photo_urls,quantity"

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

    var goodsItem: GoodsItem {
        GoodsItem(
            id: id,
            ownerID: userId,
            kind: GoodsEntryKind(inventoryKind: kind),
            status: status.flatMap(GoodsEntryStatus.init(rawValue:)),
            groupID: groupId,
            memberID: characterId,
            goodsTypeID: goodsTypeId,
            title: title,
            imageURL: photoUrls?.compactMap(URL.init(string:)).first,
            tags: [],
            quantity: max(1, quantity ?? 1),
            lockedQuantity: max(0, lockedQty ?? 0),
            marketAvailableQuantity: marketAvailableQty.map { max(0, $0) }
        )
    }

    var wishItem: WishItem {
        WishItem(
            id: id,
            ownerID: userId,
            groupID: groupId,
            memberID: characterId,
            goodsTypeID: goodsTypeId,
            title: title,
            imageURL: photoUrls?.compactMap(URL.init(string:)).first,
            tags: [],
            quantity: quantity ?? 1
        )
    }
}

struct OwnedGoodsInventoryTagRow: Decodable, Sendable {
    static let select = "inventory_id,tag:tags_master(id,label)"

    var inventoryId: UUID
    var tag: OwnedGoodsTagRow?
}

struct OwnedGoodsTagRow: Decodable, Sendable {
    var id: UUID
    var label: String

    var goodsTag: GoodsTag {
        GoodsTag(id: id, name: label)
    }
}
