import Foundation
import MegrumCore

enum TradeGoodsLookup {
    static func build(
        inventory: [GoodsItem],
        homeMatchedItems: [GoodsItem],
        homePossibleItems: [GoodsItem],
        wishes: [WishItem],
        publicTradeGoodsByUserID: [UUID: [GoodsItem]]
    ) -> [UUID: GoodsItem] {
        var lookup: [UUID: GoodsItem] = [:]
        let localWishGoods = wishes.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                kind: .wish,
                status: .active,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                imageURL: $0.imageURL,
                tags: $0.tags,
                quantity: $0.quantity
            )
        }
        let allKnownGoods = inventory
            + homeMatchedItems
            + homePossibleItems
            + localWishGoods
            + publicTradeGoodsByUserID.values.flatMap { $0 }
        for item in allKnownGoods {
            lookup[item.id] = item
        }
        return lookup
    }
}
