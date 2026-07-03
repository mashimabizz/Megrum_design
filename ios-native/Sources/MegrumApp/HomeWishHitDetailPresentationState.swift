import Foundation
import MegrumCore

struct HomeWishHitDetailPresentationState: Equatable {
    private(set) var selectedOfferIndex: Int?

    var selectedOfferIndices: Set<Int> {
        selectedOfferIndex.map { [$0] } ?? []
    }

    var canStartProposal: Bool {
        selectedOfferIndex != nil
    }

    mutating func prepareInitialSelection(preselectFirstOffer: Bool, offerGoods: [HomeMockGoods]) {
        guard preselectFirstOffer else {
            selectedOfferIndex = nil
            return
        }
        selectedOfferIndex = offerGoods.isEmpty ? nil : 0
    }

    mutating func selectOffer(at index: Int) {
        selectedOfferIndex = index
    }

    func proposalSelection(
        selection: HomeDiscoverySheetPayload,
        offerGoods: [HomeMockGoods]
    ) -> HomeDiscoveryProposalSelection? {
        guard let selectedOfferIndex,
              offerGoods.indices.contains(selectedOfferIndex)
        else {
            return nil
        }

        let selectedOfferGoods = offerGoods[selectedOfferIndex]
        return HomeDiscoveryProposalSelection(
            receiverGoodsID: selection.goods.id,
            senderGoodsIDs: [selectedOfferGoods.id],
            matchType: .forward,
            receiverGoods: selection.goods,
            senderGoods: [selectedOfferGoods],
            exchangeMethod: selection.signals.preferredProposalExchangeMethod
        )
    }
}
