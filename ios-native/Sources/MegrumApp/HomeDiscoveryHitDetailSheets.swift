import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeGoodsHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "交換内容を確認する"
    var preselectPreferredOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var selectionState = HomeListingSheetSelectionState()
    @State private var proposalConfirmation: HomeProposalStartConfirmationPayload?
    @State private var focusedWantedOptionID: UUID?
    @State private var presentedWantedOptionDetail: HomeIndividualListingDetailContext?
    private let selectionCardSize = HomeGoodsImagePanelCardSize.compact

    var body: some View {
        HomeSheetScaffold(
            bottomButton: bottomButtonTitle,
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: !selectionContext.canStartProposal,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(
                goods: selection.goods,
                conditionTags: selection.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(selection.signals),
                exchangeCalendarContext: HomePartnerExchangeCalendarContext.from(
                    signals: selection.signals,
                    ownerName: selection.goods.ownerSummary?.displayName
                ),
                listingNote: selection.individualListingSelection.listingNote,
                listingDetail: selection.individualListingSelection.detail,
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            if selectionContext.showsReceiveSelection {
                HomeSheetSectionTitle(
                    systemName: "sparkles",
                    title: "受け取るものを選ぶ",
                    trailing: selectionContext.receiveRequirementLabel
                )
                HomeGoodsImagePanelRail(
                    goods: selectionContext.receiveGoods,
                    selectedIndices: selectionState.selectedReceiveIndices,
                    selectedBannerText: "受け取る",
                    cardSize: selectionCardSize,
                    onSelect: toggleReceiveGoods
                )
            }

            HomeWantedSelectionSectionHeader(
                systemName: "person",
                title: "相手の希望から譲るを選ぶ",
                trailing: selectionContext.wantedRequirementLabel,
                showsOtherOptionsButton: selectionContext.showsWantedOptionPicker
                    && selection.individualListingSelection.detail != nil,
                onOpenOtherOptions: openWantedOptionPicker
            )
            HomeGoodsHitWantedSelectionRail(
                usesListingWantedOptions: selectionContext.usesListingWantedOptions,
                wantedOptionPreviewGoods: selectionContext.wantedOptionPreviewGoods,
                selectedWantedOptionPreviewIndices: selectionContext.selectedWantedOptionPreviewIndices,
                topTrailingBadgeTextByGoodsID: selectionContext.wantedOptionPreviewBadgeTextByGoodsID,
                wantedGoods: selectionContext.wantedGoods,
                selectedWantedIndices: selectionState.selectedWantedIndices,
                cardSize: selectionCardSize,
                onSelectWantedOptionPreviewGoods: toggleWantedOptionPreviewGoods,
                onSelectWantedGoods: toggleWantedGoods
            )

            if !selectionState.selectedWantedIndices.isEmpty {
                if let selectedCashOption = selectionContext.selectedCashOption {
                    HomeCashAmountEntryCard(
                        amountText: $selectionState.cashAmountText,
                        suggestedAmount: selectedCashOption.cashAmount
                    )
                } else {
                    HomeSheetSectionTitle(
                        systemName: "gift",
                        title: "譲るグッズを選ぶ",
                        trailing: selectionContext.offerRequirementLabel
                    )
                    if selectionContext.offerGoods.isEmpty {
                        HomeNoMatchingOfferGoodsPanel()
                    } else {
                        HomeGoodsImagePanelRail(
                            goods: selectionContext.offerGoods,
                            selectedIndices: selectionState.selectedOfferIndices,
                            selectedBannerText: "これを譲る",
                            cardSize: selectionCardSize,
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
        .sheet(item: $presentedWantedOptionDetail) { detail in
            HomeIndividualListingDetailPopup(
                detail: detail,
                selectedWantedOptionID: selectionContext.selectedWantedOptionID,
                onSelectWantedOption: selectWantedOptionFromDetail
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $proposalConfirmation) { confirmation in
            HomeProposalStartConfirmationSheet(
                payload: confirmation,
                onConfirm: confirmProposalStart
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var selectionContext: HomeGoodsHitDetailSelectionContext {
        HomeGoodsHitDetailSelectionContext(
            selection: selection,
            viewerOfferGoods: viewerOfferGoods,
            selectionState: selectionState,
            focusedWantedOptionID: focusedWantedOptionID
        )
    }

    private func toggleWantedOptionPreviewGoods(at _: Int) {
        guard let optionIndex = selectionContext.displayedWantedOptionIndex else {
            return
        }
        toggleWantedGoods(at: optionIndex)
    }

    private func toggleWantedGoods(at index: Int) {
        let context = selectionContext
        selectionState = HomeListingSheetSelectionStateReducer.togglingWanted(
            at: index,
            in: selectionState,
            itemCount: context.wantedItemCount,
            logic: context.wantedLogic
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
            itemCount: selectionContext.offerGoods.count,
            logic: selectionContext.offerLogic
        )
    }

    private func toggleReceiveGoods(at index: Int) {
        selectionState = HomeListingSheetSelectionStateReducer.togglingReceive(
            at: index,
            in: selectionState,
            itemCount: selectionContext.receiveGoods.count,
            logic: selectionContext.receiveLogic
        )
    }

    private func prepareInitialSelections() {
        let context = selectionContext
        selectionState = HomeListingSheetSelectionStateReducer.preparingInitialSelection(
            itemCount: context.wantedItemCount,
            logic: context.wantedLogic
        )
        selectionState.selectedReceiveIndices = context.initialReceiveIndices
        if !selectionState.selectedWantedIndices.isEmpty {
            fillSuggestedCashAmountIfNeeded()
            if preselectPreferredOffer {
                selectPreferredOfferIfNeeded()
            }
        }
    }

    private func resetSelections() {
        focusedWantedOptionID = nil
        prepareInitialSelections()
    }

    private func openWantedOptionPicker() {
        presentedWantedOptionDetail = selection.individualListingSelection.detail
    }

    private func selectWantedOptionFromDetail(_ option: HomeIndividualListingWantedOption) {
        focusedWantedOptionID = option.id
        selectionState = HomeListingSheetSelectionState(
            selectedWantedIndices: [0],
            selectedOfferIndices: [],
            selectedReceiveIndices: selectionState.selectedReceiveIndices,
            cashAmountText: ""
        )
        presentedWantedOptionDetail = nil
        fillSuggestedCashAmountIfNeeded()
        if preselectPreferredOffer {
            selectPreferredOfferIfNeeded()
        }
    }

    private func fillSuggestedCashAmountIfNeeded() {
        guard selectionState.cashAmountText.isEmpty,
              let amount = selectionContext.selectedCashOption?.cashAmount,
              amount > 0
        else {
            return
        }
        selectionState.cashAmountText = TradeAmountFormatter.cashInputText(from: String(amount))
    }

    private func selectPreferredOfferIfNeeded() {
        let context = selectionContext
        guard context.selectedCashOption == nil,
              selectionState.selectedOfferIndices.isEmpty,
              context.offerMinimumCount <= 1,
              let preferredOfferIndex = context.preferredOfferIndex
        else {
            return
        }
        selectionState.selectedOfferIndices = [preferredOfferIndex]
    }

    private func startProposal() {
        guard let proposalSelection = selectionContext.proposalSelection() else {
            return
        }
        proposalConfirmation = HomeProposalStartConfirmationPayload(
            proposalSelection: proposalSelection,
            receiverGoods: confirmationReceiverGoods(for: proposalSelection),
            senderGoods: selectionContext.selectedCashOption == nil ? proposalSelection.senderGoods : [],
            senderCashAmount: proposalSelection.cashAmount
        )
    }

    private func confirmProposalStart(_ selection: HomeDiscoveryProposalSelection) {
        proposalConfirmation = nil
        onStartProposal(selection)
    }

    private func confirmationReceiverGoods(for proposalSelection: HomeDiscoveryProposalSelection) -> [HomeMockGoods] {
        let receiverGoods = selectionContext.selectedReceiveGoods
        if !receiverGoods.isEmpty {
            return receiverGoods
        }
        return proposalSelection.receiverGoods.map { [$0] } ?? [selection.goods]
    }
}
