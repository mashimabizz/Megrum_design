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
            bottomButtonDisabled: !selectionContext.canStartProposal,
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
                trailing: selectionContext.selectionRequirementLabel
            )
            wantedSelectionRail

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
                        trailing: selectionContext.selectionRequirementLabel
                    )
                    if selectionContext.offerGoods.isEmpty {
                        HomeNoMatchingOfferGoodsPanel()
                    } else {
                        HomeGoodsImagePanelRail(
                            goods: selectionContext.offerGoods,
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

    private var selectionContext: HomeGoodsHitDetailSelectionContext {
        HomeGoodsHitDetailSelectionContext(
            selection: selection,
            viewerOfferGoods: viewerOfferGoods,
            selectionState: selectionState
        )
    }

    @ViewBuilder
    private var wantedSelectionRail: some View {
        if selectionContext.usesListingWantedOptions {
            HomeListingWantedOptionRail(
                options: selectionContext.wantedOptions,
                selectedIndices: selectionState.selectedWantedIndices,
                previewGoodsByOptionID: selectionContext.previewGoodsByWantedOptionID,
                onSelect: toggleWantedGoods
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: selectionContext.wantedGoods,
                selectedIndices: selectionState.selectedWantedIndices,
                onSelect: toggleWantedGoods
            )
        }
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
            logic: selectionContext.wantedLogic
        )
    }

    private func prepareInitialSelections() {
        let context = selectionContext
        selectionState = HomeListingSheetSelectionStateReducer.preparingInitialSelection(
            itemCount: context.wantedItemCount,
            logic: context.wantedLogic
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
        onStartProposal(proposalSelection)
    }
}
