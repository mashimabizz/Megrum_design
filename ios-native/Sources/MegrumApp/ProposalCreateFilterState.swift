import Foundation
import MegrumCore

struct ProposalCreateFilterState: Equatable, Sendable {
    var senderGroupID: UUID?
    var senderGoodsTypeID: UUID?
    var receiverGroupID: UUID?
    var receiverGoodsTypeID: UUID?

    func filteredSenderGoods(from goods: [GoodsItem]) -> [GoodsItem] {
        goods.filter { item in
            (senderGroupID == nil || item.groupID == senderGroupID)
                && (senderGoodsTypeID == nil || item.goodsTypeID == senderGoodsTypeID)
        }
    }

    func filteredReceiverGoods(from goods: [GoodsItem]) -> [GoodsItem] {
        goods.filter { item in
            (receiverGroupID == nil || item.groupID == receiverGroupID)
                && (receiverGoodsTypeID == nil || item.goodsTypeID == receiverGoodsTypeID)
        }
    }
}
