import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeGoodsHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "この内容で打診する"
    var preselectPreferredOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var selectionState = HomeListingSheetSelectionState()

    var body: some View {
        HomeSheetScaffold(
            bottomButton: bottomButtonTitle,
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: !canStartProposal,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(
                goods: selection.goods,
                conditionTags: selection.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromListingSignals(selection.signals),
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "person",
                title: "相手の希望から譲を選ぶ",
                trailing: selectionRequirementLabel
            )
            wantedSelectionRail

            if !selectionState.selectedWantedIndices.isEmpty {
                if let selectedCashOption {
                    HomeCashAmountEntryCard(
                        amountText: $selectionState.cashAmountText,
                        suggestedAmount: selectedCashOption.cashAmount
                    )
                } else {
                    HomeSheetSectionTitle(
                        systemName: "gift",
                        title: "譲るグッズを選ぶ",
                        trailing: selectionRequirementLabel
                    )
                    if offerGoods.isEmpty {
                        HomeNoMatchingOfferGoodsPanel()
                    } else {
                        HomeGoodsImagePanelRail(
                            goods: offerGoods,
                            selectedIndices: selectionState.selectedOfferIndices,
                            selectedBannerText: "これを譲る",
                            onSelect: toggleOfferGoods
                        )
                    }
                }
            }

            if showsOtherExchangeRows {
                HomeOtherExchangeRows(
                    addedCandidateIDs: addedExtraCandidateIDs,
                    excludedGoodsIDs: [selection.goods.id],
                    onOpenNestedSheet: onOpenNestedSheet
                )
            }
        }
        .onAppear(perform: prepareInitialSelections)
        .onChange(of: selection.id) { _, _ in
            resetSelections()
        }
    }

    private var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    private var wantedOptions: [HomeIndividualListingWantedOption] {
        selection.individualListingSelection.wantedOptions
    }

    private var usesListingWantedOptions: Bool {
        !wantedOptions.isEmpty
    }

    private var allOfferGoods: [HomeMockGoods] {
        HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    private var offerGoods: [HomeMockGoods] {
        guard usesListingWantedOptions else {
            return allOfferGoods
        }
        let matchingIDs = Set(selectedWantedOptions.flatMap(\.matchingGoodsIDs))
        guard !matchingIDs.isEmpty else {
            return []
        }
        return allOfferGoods.filter { matchingIDs.contains($0.id) }
    }

    private var wantedLogic: ListingLogic {
        selection.individualListingSelection.wantedLogic
    }

    private var wantedItemCount: Int {
        usesListingWantedOptions ? wantedOptions.count : wantedGoods.count
    }

    private var selectedWantedOptions: [HomeIndividualListingWantedOption] {
        guard usesListingWantedOptions else {
            return []
        }
        return selectionState.selectedWantedIndices
            .sorted()
            .compactMap { wantedOptions.indices.contains($0) ? wantedOptions[$0] : nil }
    }

    private var selectedCashOption: HomeIndividualListingWantedOption? {
        selectedWantedOptions.first { $0.isCashOffer }
    }

    private var cashAmountValue: Int? {
        TradeAmountFormatter.cashInputValue(from: selectionState.cashAmountText)
    }

    private var selectionRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic)
    }

    private var canStartProposal: Bool {
        if selectedCashOption != nil {
            return !selectionState.selectedWantedIndices.isEmpty && cashAmountValue != nil
        }
        return !selectionState.selectedWantedIndices.isEmpty && !selectionState.selectedOfferIndices.isEmpty
    }

    @ViewBuilder
    private var wantedSelectionRail: some View {
        if usesListingWantedOptions {
            HomeListingWantedOptionRail(
                options: wantedOptions,
                selectedIndices: selectionState.selectedWantedIndices,
                previewGoodsByOptionID: previewGoodsByWantedOptionID,
                onSelect: toggleWantedGoods
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: wantedGoods,
                selectedIndices: selectionState.selectedWantedIndices,
                onSelect: toggleWantedGoods
            )
        }
    }

    private var previewGoodsByWantedOptionID: [UUID: HomeMockGoods] {
        HomeListingWantedOptionPreviewPolicy.previewGoodsByOptionID(
            options: wantedOptions,
            goodsPool: wantedOptionPreviewGoodsPool
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

    private func toggleWantedGoods(at index: Int) {
        selectionState = HomeListingSheetSelectionStateReducer.togglingWanted(
            at: index,
            in: selectionState,
            itemCount: wantedItemCount,
            logic: wantedLogic
        )
        if selectionState.selectedWantedIndices.isEmpty {
            return
        }
        fillSuggestedCashAmountIfNeeded()
        selectPreferredOfferIfNeeded()
    }

    private func toggleOfferGoods(at index: Int) {
        selectionState = HomeListingSheetSelectionStateReducer.togglingOffer(
            at: index,
            in: selectionState,
            itemCount: offerGoods.count,
            logic: wantedLogic
        )
    }

    private func prepareInitialSelections() {
        selectionState = HomeListingSheetSelectionStateReducer.preparingInitialSelection(
            itemCount: wantedItemCount,
            logic: wantedLogic
        )
        if !selectionState.selectedWantedIndices.isEmpty {
            fillSuggestedCashAmountIfNeeded()
            if preselectPreferredOffer {
                selectPreferredOfferIfNeeded()
            }
        }
    }

    private func resetSelections() {
        prepareInitialSelections()
    }

    private func fillSuggestedCashAmountIfNeeded() {
        guard selectionState.cashAmountText.isEmpty,
              let amount = selectedCashOption?.cashAmount,
              amount > 0
        else {
            return
        }
        selectionState.cashAmountText = TradeAmountFormatter.cashInputText(from: String(amount))
    }

    private func selectPreferredOfferIfNeeded() {
        guard selectedCashOption == nil,
              selectionState.selectedOfferIndices.isEmpty,
              let preferredOfferIndex
        else {
            return
        }
        selectionState.selectedOfferIndices = [preferredOfferIndex]
    }

    private var preferredOfferIndex: Int? {
        guard let preferredOfferGoodsID = selection.preferredOfferGoodsID else {
            return nil
        }
        return offerGoods.firstIndex { $0.id == preferredOfferGoodsID }
    }

    private func startProposal() {
        if let cashAmountValue {
            onStartProposal(
                HomeDiscoveryProposalSelection(
                    receiverGoodsID: selection.goods.id,
                    senderGoodsIDs: [],
                    matchType: .perfect,
                    receiverGoods: selection.goods,
                    senderGoods: [],
                    exchangeMethod: selection.signals.preferredProposalExchangeMethod,
                    cashAmount: cashAmountValue
                )
            )
            return
        }
        let senderGoods = selectionState.selectedOfferIndices
            .sorted()
            .compactMap { index in
                offerGoods.indices.contains(index) ? offerGoods[index] : nil
            }
        guard !senderGoods.isEmpty else {
            return
        }
        onStartProposal(
            HomeDiscoveryProposalSelection(
                receiverGoodsID: selection.goods.id,
                senderGoodsIDs: senderGoods.map(\.id),
                matchType: .perfect,
                receiverGoods: selection.goods,
                senderGoods: senderGoods,
                exchangeMethod: selection.signals.preferredProposalExchangeMethod,
                cashAmount: nil
            )
        )
    }
}

struct HomeWishHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "この内容で打診する"
    var preselectFirstOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var selectedOfferIndex: Int?

    var body: some View {
        HomeSheetScaffold(
            bottomButton: bottomButtonTitle,
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: selectedOfferIndex == nil,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(
                goods: selection.goods,
                conditionTags: selection.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromListingSignals(selection.signals),
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "gift",
                title: "あなたが譲れる相手のWish"
            )

            if offerGoods.isEmpty {
                HomeNoMatchingOfferGoodsPanel()
            } else {
                HomeGoodsImagePanelPagedGrid(
                    goods: offerGoods,
                    selectedIndices: selectedOfferIndex.map { [$0] } ?? [],
                    selectedBannerText: "これを譲る",
                    onSelect: { selectedOfferIndex = $0 }
                )
                .overlay(alignment: .bottomTrailing) {
                    Text("\(offerGoods.count)件の候補")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                        }
                        .padding(.trailing, 18)
                        .padding(.bottom, 2)
                }
            }

            if showsOtherExchangeRows {
                HomeOtherExchangeRows(
                    addedCandidateIDs: addedExtraCandidateIDs,
                    excludedGoodsIDs: [selection.goods.id],
                    onOpenNestedSheet: onOpenNestedSheet
                )
            }
        }
        .onAppear(perform: prepareInitialSelection)
        .onChange(of: selection.id) { _, _ in
            prepareInitialSelection()
        }
    }

    private var offerGoods: [HomeMockGoods] {
        HomeWishHitOfferGoodsPolicy.offerGoods(
            viewerOfferGoods: viewerOfferGoods,
            matchedOfferGoodsIDs: selection.signals.wishMatchedOfferGoodsIDs,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    private func prepareInitialSelection() {
        guard preselectFirstOffer else {
            selectedOfferIndex = nil
            return
        }
        selectedOfferIndex = offerGoods.isEmpty ? nil : 0
    }

    private func startProposal() {
        guard let selectedOfferIndex,
              offerGoods.indices.contains(selectedOfferIndex)
        else {
            return
        }
        onStartProposal(
            HomeDiscoveryProposalSelection(
                receiverGoodsID: selection.goods.id,
                senderGoodsIDs: [offerGoods[selectedOfferIndex].id],
                matchType: .forward,
                receiverGoods: selection.goods,
                senderGoods: [offerGoods[selectedOfferIndex]],
                exchangeMethod: selection.signals.preferredProposalExchangeMethod
            )
        )
    }
}

enum HomeWishHitOfferGoodsPolicy {
    static func offerGoods(
        viewerOfferGoods: [HomeMockGoods],
        matchedOfferGoodsIDs: [UUID],
        preferredOfferGoodsID: UUID?
    ) -> [HomeMockGoods] {
        let matchedOfferIDs = Set(matchedOfferGoodsIDs)
        guard !matchedOfferIDs.isEmpty else {
            return []
        }
        return HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.filter { matchedOfferIDs.contains($0.id) },
            preferredOfferGoodsID: preferredOfferGoodsID
        )
    }
}

extension HomeCandidateConditionSignals {
    var preferredProposalExchangeMethod: ExchangeMethod {
        if exchange.localExchangeSelected && exchange.postalAcceptedByBoth {
            return .both
        }
        if exchange.localExchangeSelected {
            return .hand
        }
        if exchange.postalAcceptedByBoth {
            return .mail
        }
        return .hand
    }
}
