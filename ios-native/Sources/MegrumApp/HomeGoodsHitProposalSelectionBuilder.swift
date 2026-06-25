import Foundation

enum HomeGoodsHitProposalSelectionBuilder {
    static func proposalSelection(
        selection: HomeDiscoverySheetPayload,
        selectedReceiveGoods: [HomeMockGoods],
        selectedOfferIndices: Set<Int>,
        offerGoods: [HomeMockGoods],
        cashAmountValue: Int?
    ) -> HomeDiscoveryProposalSelection? {
        let receiverGoodsCandidates = selectedReceiveGoods.isEmpty ? [selection.goods] : selectedReceiveGoods
        guard let primaryReceiverGoods = receiverGoodsCandidates.first else {
            return nil
        }

        if let cashAmountValue {
            return HomeDiscoveryProposalSelection(
                receiverGoodsID: primaryReceiverGoods.id,
                receiverGoodsIDs: receiverGoodsCandidates.map(\.id),
                senderGoodsIDs: [],
                matchType: .perfect,
                receiverGoods: primaryReceiverGoods,
                senderGoods: [],
                exchangeMethod: selection.signals.preferredProposalExchangeMethod,
                cashAmount: cashAmountValue
            )
        }

        let senderGoods = selectedOfferIndices
            .sorted()
            .compactMap { index in
                offerGoods.indices.contains(index) ? offerGoods[index] : nil
            }
        guard !senderGoods.isEmpty else {
            return nil
        }
        return HomeDiscoveryProposalSelection(
            receiverGoodsID: primaryReceiverGoods.id,
            receiverGoodsIDs: receiverGoodsCandidates.map(\.id),
            senderGoodsIDs: senderGoods.map(\.id),
            matchType: .perfect,
            receiverGoods: primaryReceiverGoods,
            senderGoods: senderGoods,
            exchangeMethod: selection.signals.preferredProposalExchangeMethod,
            cashAmount: nil
        )
    }
}
