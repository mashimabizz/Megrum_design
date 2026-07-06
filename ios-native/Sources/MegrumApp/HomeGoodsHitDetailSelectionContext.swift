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
        return prioritizedWantedOptions(selectableWantedOptions)
    }

    var receiveGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.receiveGoods(selection: selection)
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

    var wantedOptionPreviewGoods: [HomeMockGoods] {
        HomeGoodsHitWantedOptionSeriesResolver.orderedPreviewGoods(
            for: displayedWantedOption,
            usesListingWantedOptions: usesListingWantedOptions,
            previewGoodsPool: wantedOptionPreviewGoodsPool,
            allOfferGoods: allOfferGoods
        )
    }

    var wantedOptionPreviewBadgeTextByGoodsID: [UUID: String] {
        HomeGoodsHitWantedOptionSeriesResolver.badgeTextByGoodsID(
            option: displayedWantedOption,
            previewGoods: wantedOptionPreviewGoods,
            allOfferGoods: allOfferGoods
        )
    }

    var selectedWantedOptionPreviewIndices: Set<Int> {
        guard usesListingWantedOptions,
              displayedWantedOption != nil,
              !selectionState.selectedWantedIndices.isEmpty
        else {
            return []
        }
        return Set(wantedOptionPreviewGoods.indices)
    }

    var displayedWantedOptionIndex: Int? {
        guard let option = displayedWantedOption else {
            return nil
        }
        return wantedOptions.firstIndex { $0.id == option.id }
    }

    var allOfferGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.allOfferGoods(
            viewerOfferGoods: viewerOfferGoods,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    var offerGoods: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.offerGoods(
            usesListingWantedOptions: usesListingWantedOptions,
            allOfferGoods: allOfferGoods,
            selectedWantedOptions: selectedWantedOptions
        )
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

    /// 相手の選択肢が要求する譲るグッズの数（手持ち数でクランプしない）。
    var offerRequiredCount: Int {
        HomeListingSelectionPolicy.requiredOfferCount(
            logic: offerLogic,
            designatedCount: offerDesignatedCount,
            minimumCount: offerMinimumCount
        )
    }

    private var offerDesignatedCount: Int {
        if selectedWantedOptions.count == 1, let option = selectedWantedOptions.first {
            return option.goodsIDs.isEmpty ? offerGoods.count : option.goodsIDs.count
        }
        return wantedGoods.count
    }

    private var offerSelectionIsSatisfied: Bool {
        guard offerGoods.count >= offerRequiredCount else {
            // 条件（グループ・メンバー・種別・シリーズ）に合う手持ちが
            // 必要数に満たない場合は打診不可。
            return false
        }
        return selectionState.selectedOfferIndices.count >= offerRequiredCount
    }

    func proposalSelection() -> HomeDiscoveryProposalSelection? {
        HomeGoodsHitProposalSelectionBuilder.proposalSelection(
            selection: selection,
            selectedReceiveGoods: selectedReceiveGoods,
            selectedOfferIndices: selectionState.selectedOfferIndices,
            offerGoods: offerGoods,
            cashAmountValue: cashAmountValue
        )
    }

    private var wantedOptionPreviewGoodsPool: [HomeMockGoods] {
        HomeGoodsHitDetailGoodsResolver.wantedOptionPreviewGoodsPool(
            allOfferGoods: allOfferGoods,
            wantedGoods: wantedGoods,
            selectedGoods: selection.goods
        )
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

    private var displayedWantedOption: HomeIndividualListingWantedOption? {
        selectedWantedOptions.first ?? focusedWantedOption ?? wantedOptions.first
    }

    private func prioritizedWantedOptions(_ options: [HomeIndividualListingWantedOption]) -> [HomeIndividualListingWantedOption] {
        HomeGoodsHitWantedOptionSeriesResolver.prioritizedWantedOptions(
            options,
            usesListingWantedOptions: usesListingWantedOptions,
            previewGoodsPool: wantedOptionPreviewGoodsPool,
            allOfferGoods: allOfferGoods
        )
    }
}
