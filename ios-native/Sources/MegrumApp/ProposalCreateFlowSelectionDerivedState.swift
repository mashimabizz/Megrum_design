import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var selectableSenderGoods: [GoodsItem] {
        let senderGoods = MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
        guard let viewerID = appState.viewer?.id else {
            return senderGoods
        }
        return senderGoods.filter { $0.ownerID == viewerID }
    }

    var receiverChoiceGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[targetItem.ownerID] ?? []
        return MatchRelationComposer.deduplicatedGoods([targetItem] + loaded)
            .filter { $0.marketAvailableQuantity > 0 }
    }

    var orderedSenderGoodsIDs: [UUID] {
        return selectableSenderGoods.map(\.id).filter { selectedSenderGoodsIDs.contains($0) }
    }

    var orderedReceiverGoodsIDs: [UUID] {
        return receiverChoiceGoods.map(\.id).filter { selectedReceiverGoodsIDs.contains($0) }
    }

    var selectedSenderGoods: [GoodsItem] {
        return selectableSenderGoods.filter { selectedSenderGoodsIDs.contains($0.id) }
    }

    var selectedReceiverGoods: [GoodsItem] {
        return receiverChoiceGoods.filter { selectedReceiverGoodsIDs.contains($0.id) }
    }

    var resolvedReceiverGoodsIDs: [UUID] {
        orderedReceiverGoodsIDs
    }
}
