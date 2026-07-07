import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeGoodsHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    /// 「他にも交換できそうなもの」に出す同じ相手の他候補（ホーム構造）。iter1226.383 / FB6-1。
    var otherExchangeCandidates: HomeOtherExchangeCandidateGroups = .empty
    var bottomButtonTitle: String = "交換内容を確認する"
    var preselectPreferredOffer: Bool = true
    /// ガイドツアーのデモ用：選択済み状態を注入して「実際の画面状態」を再現する（通常は nil）。
    var initialSelectionState: HomeListingSheetSelectionState? = nil
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
            HomeCandidateSheetHeader(
                owner: selection.goods.ownerSummary,
                fallbackName: selection.goods.ownerDisplayName?.nilIfBlank ?? "ユーザー",
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            // 選択肢ピル（相手希望を切替）を常時表示。旧「他の選択肢」ボタンはこれに集約。iter1226.374。
            if selectionContext.showsWantedOptionPicker {
                HomeWantedOptionPills(
                    options: selectionContext.pillWantedOptions,
                    selectedID: selectionContext.selectedWantedOptionID,
                    onSelect: selectWantedOption
                )
            }

            if selectionContext.selectedCashOption != nil, let cashModel = selectionContext.cashBlockModel() {
                // 定価も他選択肢と同じ左右構造（うけとる ⇄ ゆずる＝金額入力）。iter1226.379。
                HomeDealCashBlockView(
                    model: cashModel,
                    amountText: $selectionState.cashAmountText,
                    onToggleReceive: toggleReceiveGoods
                )
            } else if let dealModel = selectionContext.dealBlockModel() {
                // 取引ブロック（3列：受け取る｜相手希望｜譲る）。notes/19 候補シート再設計。
                HomeDealBlockView(
                    model: dealModel,
                    onToggleReceive: toggleReceiveGoods,
                    onToggleOffer: toggleOfferGoods
                )

                // 条件パターンは「条件のグッズを確認！」（参考画像 or 画像検索）を続けて出す。
                if let seriesCheck = selectionContext.conditionSeriesCheckModel() {
                    HomeConditionSeriesCheckSection(model: seriesCheck)
                }
            } else {
                legacyDealSelection
            }

            HomeCandidateDealAboutSection(
                verdict: HomeConditionVerdictPolicy.make(
                    from: selection.signals,
                    partnerPaymentNote: selection.goods.ownerPaymentNote
                ),
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(selection.signals),
                paymentSummaryText: selection.goods.ownerPaymentSummaryText,
                exchangeCalendarContext: HomePartnerExchangeCalendarContext.from(
                    signals: selection.signals,
                    ownerName: selection.goods.ownerSummary?.displayName
                ),
                listingNote: selection.individualListingSelection.listingNote,
                listingUpdatedAt: selection.individualListingSelection.listingUpdatedAt,
                goodsUpdatedAt: selection.goods.updatedAt
            )

            if showsOtherExchangeRows {
                HomeSamePartnerExchangeSection(
                    groups: otherExchangeCandidates,
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

    /// 個別募集の選択肢が無い候補（旧フォールバック）用の選択UI。取引ブロックが使えない時だけ表示。
    @ViewBuilder
    private var legacyDealSelection: some View {
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

        if let singleWantedSummary = selectionContext.singleWantedOptionSummary {
            HomeWantedSingleOptionContextRow(summary: singleWantedSummary)
        } else {
            HomeWantedSelectionSectionHeader(
                systemName: "person",
                title: "相手の希望から譲るを選ぶ",
                trailing: selectionContext.wantedRequirementLabel,
                showsOtherOptionsButton: false,
                onOpenOtherOptions: {}
            )
            HomeGoodsHitWantedSelectionRail(
                usesListingWantedOptions: selectionContext.usesListingWantedOptions,
                wantedOptionPreviewGoods: selectionContext.wantedOptionPreviewGoods,
                selectedWantedOptionPreviewIndices: selectionContext.selectedWantedOptionPreviewIndices,
                topTrailingBadgeTextByGoodsID: selectionContext.wantedOptionPreviewBadgeTextByGoodsID,
                wantedGoods: selectionContext.wantedGoods,
                selectedWantedIndices: selectionState.selectedWantedIndices,
                cardSize: selectionCardSize,
                conditionCard: selectionContext.displayedWantedConditionCard,
                onSelectWantedOptionPreviewGoods: toggleWantedOptionPreviewGoods,
                onSelectWantedGoods: toggleWantedGoods,
                onToggleConditionCard: { toggleWantedOptionPreviewGoods(at: 0) }
            )
        }

        if !selectionState.selectedWantedIndices.isEmpty, selectionContext.selectedCashOption == nil {
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

    /// 選択肢ピルで相手希望を切替。旧「他の選択肢」ポップアップの選択と同じ挙動。iter1226.374。
    private func selectWantedOption(_ id: UUID) {
        guard let option = selectionContext.wantedOption(withID: id) else {
            return
        }
        selectWantedOptionFromDetail(option)
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
        if let initialSelectionState {
            selectionState = initialSelectionState
            if !selectionState.selectedWantedIndices.isEmpty {
                fillSuggestedCashAmountIfNeeded()
                if preselectPreferredOffer {
                    selectPreferredOfferIfNeeded()
                }
            }
            return
        }
        let context = selectionContext
        selectionState = HomeListingSheetSelectionStateReducer.preparingInitialSelection(
            itemCount: context.wantedItemCount,
            logic: context.wantedLogic
        )
        selectionState.selectedReceiveIndices = context.initialReceiveIndices
        if context.usesListingWantedOptions {
            // 候補シートの相手希望は必ず「選択肢1つ」を表示する。複数選択肢で全部選択され定価が混ざる不具合を防ぐ。iter1226.379。
            selectFirstWantedOption()
        } else if !selectionState.selectedWantedIndices.isEmpty {
            fillSuggestedCashAmountIfNeeded()
            if preselectPreferredOffer {
                selectPreferredOfferIfNeeded()
            }
        }
    }

    private func selectFirstWantedOption() {
        guard let first = selectionContext.pillWantedOptions.first else {
            selectionState.selectedWantedIndices = []
            return
        }
        focusedWantedOptionID = first.id
        selectionState.selectedWantedIndices = [0]
        fillSuggestedCashAmountIfNeeded()
        if preselectPreferredOffer {
            selectPreferredOfferIfNeeded()
        }
    }

    private func resetSelections() {
        focusedWantedOptionID = nil
        prepareInitialSelections()
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
        guard var proposalSelection = selectionContext.proposalSelection() else {
            return
        }
        let verdict = HomeConditionVerdictPolicy.make(
            from: selection.signals,
            partnerPaymentNote: selection.goods.ownerPaymentNote
        )
        proposalSelection.suggestedMessage = ProposalSuggestedMessageBuilder.make(from: verdict)
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
