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
    @State private var proposalConfirmation: HomeProposalStartConfirmationPayload?
    @State private var focusedWantedOptionID: UUID?
    @State private var presentedWantedOptionDetail: HomeIndividualListingDetailContext?

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
                    onSelect: toggleReceiveGoods
                )
            }

            HomeWantedSelectionSectionHeader(
                systemName: "person",
                title: "相手の希望から譲を選ぶ",
                trailing: selectionContext.wantedRequirementLabel,
                showsOtherOptionsButton: selectionContext.showsWantedOptionPicker
                    && selection.individualListingSelection.detail != nil,
                onOpenOtherOptions: openWantedOptionPicker
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
                        trailing: selectionContext.offerRequirementLabel
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

private struct HomeWantedSelectionSectionHeader: View {
    var systemName: String
    var title: String
    var trailing: String?
    var showsOtherOptionsButton: Bool
    var onOpenOtherOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 9) {
                    Image(systemName: systemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 4)

                if showsOtherOptionsButton {
                    Button("他の選択肢", systemImage: "list.bullet.rectangle", action: onOpenOtherOptions)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .padding(.horizontal, 9)
                        .frame(height: 30)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                }

                if let trailing {
                    Text(trailing)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        }
    }
}
