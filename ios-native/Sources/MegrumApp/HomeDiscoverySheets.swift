import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoverySheetView: View {
    var sheet: HomeDiscoverySheet
    var viewerOfferGoods: [HomeMockGoods] = []
    var onClose: (() -> Void)? = nil
    var onAddExtraCandidate: (HomeExtraHitPayload) -> Void = { _ in }
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    @State private var nestedSheet: HomeDiscoverySheet?
    @State private var addedExtraCandidateIDs: Set<UUID> = []

    var body: some View {
        sheetContent
            .sheet(item: $nestedSheet) { sheet in
                HomeDiscoverySheetView(
                    sheet: sheet,
                    viewerOfferGoods: viewerOfferGoods,
                    onClose: {
                        nestedSheet = nil
                    },
                    onAddExtraCandidate: { payload in
                        addedExtraCandidateIDs.insert(payload.goods.id)
                        nestedSheet = nil
                    },
                    onStartProposal: onStartProposal
                )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch sheet {
        case .goodsHit(let payload):
            HomeGoodsHitDetailSheet(
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                onOpenNestedSheet: { nestedSheet = $0 },
                onStartProposal: onStartProposal
            )
        case .wishHit(let payload):
            HomeWishHitDetailSheet(
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                onOpenNestedSheet: { nestedSheet = $0 },
                onStartProposal: onStartProposal
            )
        case .havesLookup(let payload):
            HomeHavesLookupSheet(
                payload: payload,
                onOpenNestedSheet: { nestedSheet = $0 }
            )
        case .extraListingHit(let payload), .extraWishHit(let payload):
            switch payload.kind {
            case .listing:
                HomeExtraHitDetailSheet(
                    payload: payload,
                    viewerOfferGoods: viewerOfferGoods,
                    onClose: onClose,
                    onAddCandidate: {
                        onAddExtraCandidate(payload)
                    }
                )
            case .wish:
                HomeWishHitDetailSheet(
                    selection: payload.sheetPayload,
                    viewerOfferGoods: viewerOfferGoods,
                    addedExtraCandidateIDs: addedExtraCandidateIDs,
                    onOpenNestedSheet: { nestedSheet = $0 },
                    onStartProposal: onStartProposal
                )
            }
        }
    }
}

private struct HomeGoodsHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    @State private var selectionState = HomeListingSheetSelectionState()

    var body: some View {
        HomeSheetScaffold(
            bottomButton: "この内容で打診する",
            showsWishCopyButton: true,
            bottomButtonDisabled: !canStartProposal,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(goods: selection.goods, conditionTags: selection.conditionTags)

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "person",
                title: "相手が欲しいグッズから選ぶ",
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
                        title: "選んだグッズはどれと一致する？",
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

            HomeOtherExchangeRows(
                addedCandidateIDs: addedExtraCandidateIDs,
                excludedGoodsIDs: [selection.goods.id],
                onOpenNestedSheet: onOpenNestedSheet
            )
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
        let digits = selectionState.cashAmountText.filter { $0.isNumber }
        guard !digits.isEmpty else {
            return nil
        }
        return Int(digits).flatMap { $0 > 0 ? $0 : nil }
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
        Dictionary(uniqueKeysWithValues: wantedOptions.compactMap { option in
            guard option.kind == .goods,
                  let previewGoods = allOfferGoods.first(where: { option.matchingGoodsIDs.contains($0.id) })
            else {
                return nil
            }
            return (option.id, previewGoods)
        })
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
            selectPreferredOfferIfNeeded()
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
        selectionState.cashAmountText = String(amount)
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

private struct HomeWishHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    @State private var selectedOfferIndex: Int? = 0

    var body: some View {
        HomeSheetScaffold(
            bottomButton: "この内容で打診する",
            showsWishCopyButton: true,
            bottomButtonDisabled: selectedOfferIndex == nil,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(goods: selection.goods, conditionTags: selection.conditionTags)

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "gift",
                title: "相手が欲しくてあなたが譲れるもの",
                trailing: "\(offerGoods.count)件の候補"
            )

            HomeGoodsImagePanelPagedGrid(
                goods: offerGoods,
                selectedIndices: selectedOfferIndex.map { [$0] } ?? [],
                selectedBannerText: "これを譲る",
                onSelect: { selectedOfferIndex = $0 }
            )

            HomeOtherExchangeRows(
                addedCandidateIDs: addedExtraCandidateIDs,
                excludedGoodsIDs: [selection.goods.id],
                onOpenNestedSheet: onOpenNestedSheet
            )
        }
    }

    private var offerGoods: [HomeMockGoods] {
        HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
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

private extension HomeCandidateConditionSignals {
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

private struct HomeHavesLookupSheet: View {
    var payload: HomeHavesLookupPayload
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            HomeHavesSelectedGoodsPanel(
                goods: payload.offeredGoods,
                conditionTags: payload.offeredConditionTags
            )

            if payload.shouldShowTagMatches {
                HomeDiscoverySection(
                    title: "メンバー×タグでマッチ",
                    candidates: payload.tagMatchedCandidates,
                    layout: .grid,
                    showsGridHeaderTitle: true,
                    showsSeeAllButton: false,
                    onSelect: onOpenNestedSheet
                )
            }

            if !payload.memberMatchedCandidates.isEmpty {
                HomeDiscoverySection(
                    title: "メンバーでマッチ",
                    candidates: payload.memberMatchedCandidates,
                    layout: .grid,
                    showsGridHeaderTitle: true,
                    showsSeeAllButton: false,
                    onSelect: onOpenNestedSheet
                )
            }

            if !payload.hasAnyMatches {
                HomeHavesEmptyMatchPanel()
            }
        }
    }
}

private struct HomeHavesSelectedGoodsPanel: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選んだグッズ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                    .frame(width: 118, height: 142)

                Spacer()
            }
        }
        .padding(.bottom, 2)
    }
}

private struct HomeHavesEmptyMatchPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("一致する候補はまだありません")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("このグッズを欲しがっている相手が見つかったらここに表示されます。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct HomeExtraHitDetailSheet: View {
    var payload: HomeExtraHitPayload
    var viewerOfferGoods: [HomeMockGoods]
    var onClose: (() -> Void)?
    var onAddCandidate: () -> Void
    @State private var selectionState = HomeListingSheetSelectionState()

    var body: some View {
        HomeSheetScaffold(
            bottomButton: "このグッズも交換候補に追加する",
            bottomButtonDisabled: !canAddCandidate,
            bottomButtonAction: addCandidate,
            dismissAction: onClose
        ) {
            HomeSelectedGoodsHeader(goods: payload.goods, conditionTags: payload.conditionTags)

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "person",
                title: "相手が欲しいグッズから選ぶ",
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
                        title: "選んだグッズはどれと一致する？",
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
        }
        .onAppear(perform: prepareInitialSelections)
        .onChange(of: payload.id) { _, _ in
            resetSelections()
        }
    }

    private var wantedGoods: [HomeMockGoods] {
        HomeDiscoveryFixtures.wantedGoods
    }

    private var wantedOptions: [HomeIndividualListingWantedOption] {
        payload.individualListingSelection.wantedOptions
    }

    private var usesListingWantedOptions: Bool {
        !wantedOptions.isEmpty
    }

    private var allOfferGoods: [HomeMockGoods] {
        viewerOfferGoods.isEmpty ? HomeDiscoveryFixtures.offerGoods : viewerOfferGoods
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
        payload.individualListingSelection.wantedLogic
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
        let digits = selectionState.cashAmountText.filter { $0.isNumber }
        guard !digits.isEmpty else {
            return nil
        }
        return Int(digits).flatMap { $0 > 0 ? $0 : nil }
    }

    private var selectionRequirementLabel: String {
        HomeListingSelectionPolicy.label(for: wantedLogic)
    }

    private var canAddCandidate: Bool {
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
        Dictionary(uniqueKeysWithValues: wantedOptions.compactMap { option in
            guard option.kind == .goods,
                  let previewGoods = allOfferGoods.first(where: { option.matchingGoodsIDs.contains($0.id) })
            else {
                return nil
            }
            return (option.id, previewGoods)
        })
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
        fillSuggestedCashAmountIfNeeded()
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
        selectionState.cashAmountText = String(amount)
    }

    private func addCandidate() {
        guard canAddCandidate else {
            return
        }
        onAddCandidate()
    }
}

private struct HomeSheetScaffold<Content: View>: View {
    var bottomButton: String?
    var secondaryButton: String?
    var showsWishCopyButton: Bool = false
    var bottomButtonDisabled: Bool = false
    var bottomButtonAction: () -> Void = {}
    var dismissAction: (() -> Void)?
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content

                    if let bottomButton {
                        Button(action: bottomButtonAction) {
                            HStack(spacing: 10) {
                                Image(systemName: "ellipsis.message.fill")
                                Text(bottomButton)
                            }
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(bottomButtonDisabled)
                        .opacity(bottomButtonDisabled ? 0.48 : 1)
                        .padding(.top, 2)
                    }

                    if let secondaryButton {
                        Button(action: {}) {
                            Text(secondaryButton)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: max(proxy.size.width - 44, 0), alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button {
                        if let dismissAction {
                            dismissAction()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(MegrumTheme.ink)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.92), in: Circle())
                            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")

                    if showsWishCopyButton {
                        Button(action: {}) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(MegrumTheme.lavender.opacity(0.92), in: Circle())
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Wishに追加")
                    }
                }
                .padding(.top, 18)
                .padding(.trailing, 18)
            }
        }
        .background(MegrumTheme.canvas)
    }
}

private struct HomeSelectedGoodsHeader: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("選んだグッズ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                .frame(width: 136, height: 162)

                VStack(alignment: .leading, spacing: 10) {
                    HomeUserSummary()

                    HomeExchangeMethodBlock()

                    HomePaymentBox(summaryText: goods.ownerPaymentSummaryText)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct HomeSelectedGoodsSingleCard: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: goods,
            goodsCondition: conditionTags.goods,
            exchangeCondition: conditionTags.exchange,
            paymentCondition: conditionTags.payment,
            prominence: 1,
            showsConditionOverlay: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選んだグッズ")
    }
}

private struct HomeUserSummary: View {
    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            HomeAvatar(symbol: "M")
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("mii_交換用 24歳 女")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 6) {
                    Text("★ 4.8")
                        .foregroundStyle(MegrumTheme.lavender)
                    Text("｜")
                        .foregroundStyle(MegrumTheme.muted.opacity(0.6))
                    Text("交換32件")
                        .fontWeight(.regular)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
            }
        }
    }
}

private struct HomeExchangeMethodBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                Text("現地交換")
            }
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.top, 1)
                Text("福岡県 / 博多駅近郊")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HomePaymentBox: View {
    var summaryText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "yensign.circle")
                Text("支払い条件")
            }
            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)

            Text(summaryText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ok)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
