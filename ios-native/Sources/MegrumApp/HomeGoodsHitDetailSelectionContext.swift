import Foundation
import MegrumCore

struct HomeGoodsHitDetailSelectionContext {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var selectionState: HomeListingSheetSelectionState

    var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    var wantedOptions: [HomeIndividualListingWantedOption] {
        selection.individualListingSelection.wantedOptions
    }

    var usesListingWantedOptions: Bool {
        !wantedOptions.isEmpty
    }

    var allOfferGoods: [HomeMockGoods] {
        HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    var offerGoods: [HomeMockGoods] {
        guard usesListingWantedOptions else {
            return allOfferGoods
        }
        let matchingIDs = Set(selectedWantedOptions.flatMap(\.matchingGoodsIDs))
        guard !matchingIDs.isEmpty else {
            return []
        }
        return allOfferGoods.filter { matchingIDs.contains($0.id) }
    }

    var wantedLogic: ListingLogic {
        selection.individualListingSelection.wantedLogic
    }

    var wantedItemCount: Int {
        usesListingWantedOptions ? wantedOptions.count : wantedGoods.count
    }

    var selectedWantedOptions: [HomeIndividualListingWantedOption] {
        guard usesListingWantedOptions else {
            return []
        }
        return selectionState.selectedWantedIndices
            .sorted()
            .compactMap { wantedOptions.indices.contains($0) ? wantedOptions[$0] : nil }
    }

    var selectedCashOption: HomeIndividualListingWantedOption? {
        selectedWantedOptions.first { $0.isCashOffer }
    }

    var cashAmountValue: Int? {
        TradeAmountFormatter.cashInputValue(from: selectionState.cashAmountText)
    }

    var selectionRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic)
    }

    var canStartProposal: Bool {
        if selectedCashOption != nil {
            return !selectionState.selectedWantedIndices.isEmpty && cashAmountValue != nil
        }
        return !selectionState.selectedWantedIndices.isEmpty && !selectionState.selectedOfferIndices.isEmpty
    }

    var previewGoodsByWantedOptionID: [UUID: HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: wantedOptions,
            goodsPool: wantedOptionPreviewGoodsPool
        )
    }

    var preferredOfferIndex: Int? {
        guard let preferredOfferGoodsID = selection.preferredOfferGoodsID else {
            return nil
        }
        return offerGoods.firstIndex { $0.id == preferredOfferGoodsID }
    }

    func proposalSelection() -> HomeDiscoveryProposalSelection? {
        if let cashAmountValue {
            return HomeDiscoveryProposalSelection(
                receiverGoodsID: selection.goods.id,
                senderGoodsIDs: [],
                matchType: .perfect,
                receiverGoods: selection.goods,
                senderGoods: [],
                exchangeMethod: selection.signals.preferredProposalExchangeMethod,
                cashAmount: cashAmountValue
            )
        }

        let senderGoods = selectionState.selectedOfferIndices
            .sorted()
            .compactMap { index in
                offerGoods.indices.contains(index) ? offerGoods[index] : nil
            }
        guard !senderGoods.isEmpty else {
            return nil
        }
        return HomeDiscoveryProposalSelection(
            receiverGoodsID: selection.goods.id,
            senderGoodsIDs: senderGoods.map(\.id),
            matchType: .perfect,
            receiverGoods: selection.goods,
            senderGoods: senderGoods,
            exchangeMethod: selection.signals.preferredProposalExchangeMethod,
            cashAmount: nil
        )
    }

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.uniqueGoodsPool([
            allOfferGoods,
            wantedGoods,
            HomeDiscoveryFixtures.offerGoods,
            HomeDiscoveryFixtures.wantedGoods,
            [selection.goods]
        ])
    }
}
