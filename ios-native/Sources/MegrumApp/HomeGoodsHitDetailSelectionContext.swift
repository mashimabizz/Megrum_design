import Foundation
import MegrumCore

struct HomeGoodsHitDetailSelectionContext {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var selectionState: HomeListingSheetSelectionState
    var focusedWantedOptionID: UUID?

    var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    var wantedOptions: [HomeIndividualListingWantedOption] {
        if let focusedWantedOption {
            return [focusedWantedOption]
        }
        return selectableWantedOptions
    }

    var receiveGoods: [HomeMockGoods] {
        let offeredItems = selection.individualListingSelection.detail?.offeredItems ?? []
        let mappedGoods = offeredItems.enumerated().map { index, item in
            if item.id == selection.goods.id {
                return selection.goods
            }
            let ownerID = selection.goods.ownerID ?? HomeDiscoveryFixtures.ownerID
            return HomeMockGoods.from(
                item: GoodsItem(
                    id: item.id,
                    ownerID: ownerID,
                    title: item.title,
                    imageURL: item.imageURL,
                    quantity: item.quantity,
                    ownerPrefecture: selection.goods.ownerPrefecture,
                    ownerDisplayName: selection.goods.ownerDisplayName,
                    ownerHandle: selection.goods.ownerHandle,
                    ownerAvatarURL: selection.goods.ownerAvatarURL,
                    ownerGender: selection.goods.ownerGender,
                    ownerAge: selection.goods.ownerAge,
                    ownerAverageStars: selection.goods.ownerAverageStars,
                    ownerEvaluationCount: selection.goods.ownerEvaluationCount,
                    ownerCompletedTradeCount: selection.goods.ownerCompletedTradeCount,
                    ownerPaymentMethods: selection.goods.ownerPaymentMethods,
                    ownerPaymentNote: selection.goods.ownerPaymentNote
                ),
                index: index,
                goodsTypes: []
            )
        }
        return mappedGoods.isEmpty ? [selection.goods] : mappedGoods
    }

    var usesListingWantedOptions: Bool {
        !availableWantedOptions.isEmpty
    }

    var showsWantedOptionPicker: Bool {
        availableWantedOptions.count > 1
    }

    var selectedWantedOptionID: UUID? {
        selectedWantedOptions.first?.id ?? focusedWantedOptionID ?? wantedOptions.first?.id
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

    var wantedMinimumCount: Int {
        selection.individualListingSelection.wantedMinimumCount
    }

    var receiveLogic: ListingLogic {
        selection.individualListingSelection.detail?.offeredLogic ?? selection.individualListingSelection.offeredLogic
    }

    var receiveMinimumCount: Int {
        selection.individualListingSelection.detail?.offeredMinimumCount ?? selection.individualListingSelection.offeredMinimumCount
    }

    var showsReceiveSelection: Bool {
        receiveLogic == .atLeast && receiveGoods.count > 1
    }

    var wantedItemCount: Int {
        usesListingWantedOptions ? wantedOptions.count : wantedGoods.count
    }

    var receiveItemCount: Int {
        receiveGoods.count
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

    var selectedReceiveGoods: [HomeMockGoods] {
        selectionState.selectedReceiveIndices
            .sorted()
            .compactMap { receiveGoods.indices.contains($0) ? receiveGoods[$0] : nil }
    }

    var cashAmountValue: Int? {
        TradeAmountFormatter.cashInputValue(from: selectionState.cashAmountText)
    }

    var wantedRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic, minimumCount: wantedMinimumCount)
    }

    var receiveRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: receiveLogic, minimumCount: receiveMinimumCount)
    }

    var offerLogic: ListingLogic {
        guard selectedWantedOptions.count == 1, let option = selectedWantedOptions.first else {
            return wantedLogic
        }
        return option.logic
    }

    var offerMinimumCount: Int {
        guard selectedWantedOptions.count == 1, let option = selectedWantedOptions.first else {
            return wantedMinimumCount
        }
        return option.minimumCount
    }

    var offerRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: offerLogic, minimumCount: offerMinimumCount)
    }

    var canStartProposal: Bool {
        guard receiveSelectionIsSatisfied, wantedSelectionIsSatisfied else {
            return false
        }
        if selectedCashOption != nil {
            return cashAmountValue != nil
        }
        return offerSelectionIsSatisfied
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

    var initialReceiveIndices: Set<Int> {
        guard !showsReceiveSelection else {
            return []
        }
        switch receiveLogic {
        case .all:
            return Set(receiveGoods.indices)
        case .one:
            return preferredReceiveIndex.map { [$0] } ?? [0]
        case .atLeast:
            if receiveGoods.count <= receiveMinimumCount {
                return Set(receiveGoods.indices)
            }
            return []
        }
    }

    private var receiveSelectionIsSatisfied: Bool {
        HomeListingSelectionPolicy.isSatisfied(
            selectedCount: selectedReceiveGoods.count,
            itemCount: receiveItemCount,
            logic: receiveLogic,
            minimumCount: receiveMinimumCount
        )
    }

    private var wantedSelectionIsSatisfied: Bool {
        HomeListingSelectionPolicy.isSatisfied(
            selectedCount: selectionState.selectedWantedIndices.count,
            itemCount: wantedItemCount,
            logic: wantedLogic,
            minimumCount: wantedMinimumCount
        )
    }

    private var offerSelectionIsSatisfied: Bool {
        HomeListingSelectionPolicy.isSatisfied(
            selectedCount: selectionState.selectedOfferIndices.count,
            itemCount: offerGoods.count,
            logic: offerLogic,
            minimumCount: offerMinimumCount
        )
    }

    func proposalSelection() -> HomeDiscoveryProposalSelection? {
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

        let senderGoods = selectionState.selectedOfferIndices
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

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.uniqueGoodsPool([
            allOfferGoods,
            wantedGoods,
            HomeDiscoveryFixtures.offerGoods,
            HomeDiscoveryFixtures.wantedGoods,
            [selection.goods]
        ])
    }

    private var preferredReceiveIndex: Int? {
        receiveGoods.firstIndex { $0.id == selection.goods.id }
    }

    private var selectableWantedOptions: [HomeIndividualListingWantedOption] {
        selection.individualListingSelection.wantedOptions
    }

    private var availableWantedOptions: [HomeIndividualListingWantedOption] {
        let detailOptions = selection.individualListingSelection.detail?.wantedOptions ?? []
        return detailOptions.isEmpty ? selectableWantedOptions : detailOptions
    }

    private var focusedWantedOption: HomeIndividualListingWantedOption? {
        guard let focusedWantedOptionID else {
            return nil
        }
        return availableWantedOptions.first { $0.id == focusedWantedOptionID }
    }
}
