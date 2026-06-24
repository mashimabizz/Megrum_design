import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?
    var onSaved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: IndividualListingDraft
    @State private var step: IndividualListingEditorStep
    @State private var havesTab: IndividualListingHavesStep.Tab = .goods
    @State private var haveSelectionFilter = IndividualListingSelectionFilter()
    @State private var wishSelectionFilter = IndividualListingSelectionFilter()
    @State private var stagedOptionSummaries: [IndividualListingOptionReviewItem] = []
    @State private var showsOptionReview = false
    @State private var optionToastMessage: String?
    @State private var optionToastID = UUID()
    @State private var saveErrorMessage: String?

    init(
        appState: MegrumAppState,
        preselectedWishID: UUID? = nil,
        initialOptionKind: IndividualListingOptionKind? = nil,
        initialStep: IndividualListingEditorStep = .haves,
        onSaved: (() -> Void)? = nil
    ) {
        self.appState = appState
        self.onLocalEditSaved = nil
        self.onSaved = onSaved
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: preselectedWishID))
        if let initialOptionKind {
            draft.setOptionKind(initialOptionKind)
        }
        self._draft = State(initialValue: draft)
        self._step = State(initialValue: initialOptionKind == nil ? initialStep : .options)
        self._havesTab = State(initialValue: draft.haveOfferKind == .cash ? .cash : .goods)
    }

    init(
        appState: MegrumAppState,
        editing listing: IndividualListing,
        initialStep: IndividualListingEditorStep = .haves,
        onSaved: (() -> Void)? = nil,
        onLocalEditSaved: @escaping (IndividualListing) -> Void
    ) {
        self.appState = appState
        self.onLocalEditSaved = onLocalEditSaved
        self.onSaved = onSaved
        let draft = IndividualListingDraft(mode: .edit(listing))
        self._draft = State(initialValue: draft)
        self._step = State(initialValue: initialStep)
        self._havesTab = State(initialValue: draft.haveOfferKind == .cash ? .cash : .goods)
    }

    var body: some View {
        IndividualListingEditorContent(
            draft: $draft,
            havesTab: $havesTab,
            haveSelectionFilter: $haveSelectionFilter,
            wishSelectionFilter: $wishSelectionFilter,
            step: step,
            inventory: appState.inventory,
            wishes: appState.wishes,
            genres: appState.oshiGenres,
            groups: appState.oshiGroups,
            characters: appState.oshiCharacters,
            goodsTypes: appState.goodsTypes,
            stepValidationMessage: stepValidationMessage,
            optionReviewCount: optionReviewItems.count,
            onBack: goBack,
            onSelectStep: selectStep,
            onShowOptionReview: { showsOptionReview = true },
            onToggleHave: toggleHave,
            onToggleWish: toggleWish,
            onLoadCharacters: loadConditionCharacters,
            onCreateOshiRequest: createOshiRequest
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            IndividualListingEditorBottomBar(
                step: step,
                havesTab: havesTab,
                optionKind: draft.optionKind,
                selectedHaveCount: draft.selectedHaveIDs.count,
                selectedWishCount: draft.optionKind == .condition ? max(1, draft.conditionMemberIDs.count) : draft.selectedWishIDs.count,
                stagedOptionCount: stagedOptionSummaries.count,
                haveLogic: haveLogicBinding,
                haveMinimumCount: haveMinimumCountBinding,
                wishLogic: wishLogicBinding,
                wishMinimumCount: wishMinimumCountBinding,
                usesConditionLogicChoice: draft.usesConditionLogicChoice,
                showsSelectAllVisibleButton: showsSelectAllVisibleButton,
                selectAllVisibleButtonTitle: selectAllVisibleButtonTitle,
                canSelectAllVisible: canSelectAllVisible,
                isDisabled: stepValidationMessage != nil || isSaving,
                isSaving: isSaving,
                onBack: goBack,
                onSelectAllVisible: selectAllVisibleItems,
                onAddOption: addCurrentOption,
                onPrimary: primaryAction
            )
        }
        .overlay(alignment: .bottom) {
            if let optionToastMessage {
                IndividualListingOptionAddedToast(message: optionToastMessage)
                    .padding(.bottom, 112)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showsOptionReview) {
            IndividualListingOptionReviewSheet(
                items: optionReviewItems,
                onDelete: deleteOptionReviewItem
            )
        }
        .alert(
            IndividualListingEditorSaveFailurePresentation.title,
            isPresented: saveErrorBinding
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage)
        }
        .onAppear {
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
            seedDraftDefaultsIfNeeded()
            loadSelectedConditionCharacters()
        }
        .onChange(of: appState.oshiGroups.map(\.id)) { _, _ in
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
            loadSelectedConditionCharacters()
        }
        .onChange(of: draft.conditionGroupID) { _, _ in
            loadSelectedConditionCharacters()
        }
        .onChange(of: havesTab) { _, newValue in
            draft.setHaveOfferKind(newValue == .cash ? .cash : .goods)
        }
    }

    private func toggleHave(_ item: GoodsItem) {
        draft.toggleHave(item.id, maxQuantity: draft.maxHaveQuantity(for: item))
    }

    private func toggleWish(_ item: WishItem) {
        draft.toggleWish(item.id)
    }

    private func selectAllVisibleItems() {
        switch step {
        case .haves where havesTab == .goods:
            if allVisibleHavesAreSelected {
                draft.deselectHaves(visibleHaveSelectionItems)
            } else {
                draft.selectAllHaves(visibleHaveSelectionItems)
            }
        case .options where draft.optionKind == .wish:
            if allVisibleWishesAreSelected {
                draft.deselectWishes(visibleWishSelectionItems)
            } else {
                draft.selectAllWishes(visibleWishSelectionItems)
            }
        default:
            break
        }
    }

    private var visibleHaveSelectionItems: [GoodsItem] {
        appState.inventory.filter(haveSelectionFilter.matches)
    }

    private var visibleWishSelectionItems: [WishItem] {
        appState.wishes.filter(wishSelectionFilter.matches)
    }

    private var showsSelectAllVisibleButton: Bool {
        switch step {
        case .haves:
            return havesTab == .goods
        case .options:
            return draft.optionKind == .wish
        case .exchange:
            return false
        }
    }

    private var canSelectAllVisible: Bool {
        switch step {
        case .haves where havesTab == .goods:
            return !visibleHaveSelectionItems.isEmpty
        case .options where draft.optionKind == .wish:
            return !visibleWishSelectionItems.isEmpty
        default:
            return false
        }
    }

    private var selectAllVisibleButtonTitle: String {
        switch step {
        case .haves where havesTab == .goods:
            return allVisibleHavesAreSelected
                ? IndividualListingEditorBottomBarPresentation.deselectAllVisibleTitle
                : IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        case .options where draft.optionKind == .wish:
            return allVisibleWishesAreSelected
                ? IndividualListingEditorBottomBarPresentation.deselectAllVisibleTitle
                : IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        default:
            return IndividualListingEditorBottomBarPresentation.selectAllVisibleTitle
        }
    }

    private var allVisibleHavesAreSelected: Bool {
        !visibleHaveSelectionItems.isEmpty
            && visibleHaveSelectionItems.allSatisfy { draft.selectedHaveIDs.contains($0.id) }
    }

    private var allVisibleWishesAreSelected: Bool {
        !visibleWishSelectionItems.isEmpty
            && visibleWishSelectionItems.allSatisfy { draft.selectedWishIDs.contains($0.id) }
    }

    private var haveLogicBinding: Binding<ListingLogic> {
        Binding(
            get: { draft.haveLogic },
            set: { draft.setHaveLogic($0) }
        )
    }

    private var wishLogicBinding: Binding<ListingLogic> {
        Binding(
            get: { draft.wishLogic },
            set: { draft.setWishLogic($0) }
        )
    }

    private var haveMinimumCountBinding: Binding<Int> {
        Binding(
            get: { draft.resolvedHaveMinimumCount },
            set: { draft.setHaveMinimumCount($0) }
        )
    }

    private var wishMinimumCountBinding: Binding<Int> {
        Binding(
            get: { draft.resolvedWishMinimumCount },
            set: { draft.setWishMinimumCount($0) }
        )
    }

    private func loadConditionCharacters(_ group: OshiGroup) {
        Task {
            await appState.loadOshiCharacters(group: group)
        }
    }

    private func loadSelectedConditionCharacters() {
        guard let group = appState.oshiGroups.first(where: { $0.id == draft.conditionGroupID }) else {
            return
        }
        loadConditionCharacters(group)
    }

    private func createOshiRequest(_ payload: OshiRequestSheetPayload) {
        Task {
            _ = await appState.createOshiRequest(
                OshiRequestCreateInput(
                    requestedName: payload.name,
                    requestedKind: payload.kind,
                    requestedGenreID: payload.genreID,
                    note: payload.note
                )
            )
            await appState.loadOshiGroups()
        }
    }

    private var stepValidationMessage: String? {
        IndividualListingEditorStepValidationPolicy.message(
            for: step,
            draft: draft,
            inventory: appState.inventory,
            wishes: appState.wishes
        )
    }

    private var isSaving: Bool {
        switch draft.mode {
        case .create:
            return appState.isCreatingIndividualListing
        case .edit(let listing):
            return appState.updatingIndividualListingID == listing.id
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private func save() async {
        saveErrorMessage = nil
        guard let input = draft.createInput(inventory: appState.inventory, wishes: appState.wishes) else {
            saveErrorMessage = stepValidationMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            return
        }
        if case .edit(let listing) = draft.mode {
            let primaryOptionID = listing.options.sorted { $0.position < $1.position }.first?.id
            if let updated = await appState.updateIndividualListing(
                listingID: listing.id,
                primaryOptionID: primaryOptionID,
                input: input,
                status: draft.status
            ) {
                onLocalEditSaved?(updated)
                finishSuccessfulSave()
            } else {
                saveErrorMessage = appState.errorMessage
                    ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            }
            return
        }
        let saved = await appState.createIndividualListing(
            input
        )
        if saved {
            finishSuccessfulSave()
        } else {
            saveErrorMessage = appState.errorMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
        }
    }

    private func finishSuccessfulSave() {
        dismiss()
        onSaved?()
    }

    private func goBack() {
        dismiss()
    }

    private func selectStep(_ targetStep: IndividualListingEditorStep) {
        withAnimation(.smooth(duration: 0.2)) {
            step = targetStep
        }
    }

    private func primaryAction() {
        guard stepValidationMessage == nil else {
            return
        }
        switch step {
        case .haves:
            withAnimation(.smooth(duration: 0.2)) {
                step = .options
            }
        case .options:
            withAnimation(.smooth(duration: 0.2)) {
                step = .exchange
            }
        case .exchange:
            draft.includesExchangeConditionSummary = true
            Task {
                await save()
            }
        }
    }

    private func addCurrentOption() {
        guard step == .options, stepValidationMessage == nil else {
            return
        }
        guard let item = makeCurrentOptionReviewItem(title: "選択肢\(stagedOptionSummaries.count + 1)") else {
            return
        }
        stagedOptionSummaries.append(item)
        draft.resetCurrentOptionSelection()
        showOptionAddedToast(for: item)
    }

    private func deleteOptionReviewItem(_ item: IndividualListingOptionReviewItem) {
        switch item.source {
        case .staged:
            stagedOptionSummaries = IndividualListingOptionReviewReducer.deleting(
                itemID: item.id,
                from: stagedOptionSummaries
            )
        case .current:
            clearCurrentOption()
        }
    }

    private func clearCurrentOption() {
        draft.resetCurrentOptionSelection()
    }

    private func showOptionAddedToast(for item: IndividualListingOptionReviewItem) {
        let toastID = UUID()
        optionToastID = toastID
        withAnimation(.snappy(duration: 0.18)) {
            optionToastMessage = item.addedToastMessage
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard optionToastID == toastID else {
                return
            }
            withAnimation(.snappy(duration: 0.18)) {
                optionToastMessage = nil
            }
        }
    }

    private func seedDraftDefaultsIfNeeded() {
        if step != .haves,
           draft.selectedHaveIDs.isEmpty,
           let firstHave = appState.inventory.first(where: { draft.maxHaveQuantity(for: $0) > 0 }) {
            draft.toggleHave(firstHave.id, maxQuantity: draft.maxHaveQuantity(for: firstHave))
        }
        if step == .exchange, draft.optionKind == .wish, draft.selectedWishIDs.isEmpty, let firstWish = appState.wishes.first {
            draft.toggleWish(firstWish.id)
        }
    }

    private var optionReviewItems: [IndividualListingOptionReviewItem] {
        var items = stagedOptionSummaries
        if let current = makeCurrentOptionReviewItem(
            title: items.isEmpty ? "編集中の選択肢" : "編集中",
            source: .current
        ) {
            items.append(current)
        }
        return items
    }

    private func makeCurrentOptionReviewItem(
        title: String,
        source: IndividualListingOptionReviewSource = .staged
    ) -> IndividualListingOptionReviewItem? {
        switch draft.optionKind {
        case .wish:
            let selectedWishes = appState.wishes.filter { draft.selectedWishIDs.contains($0.id) }
            guard !selectedWishes.isEmpty else {
                return nil
            }
            let wishTitles = selectedWishes
                .map { wish in
                    let quantity = draft.wishQuantity(for: wish.id)
                    return quantity > 1 ? "\(wish.title) x\(quantity)" : wish.title
                }
                .joined(separator: " / ")
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "Wish",
                detail: "\(wishTitles)（\(draft.wishLogic.displayName(minimumCount: draft.resolvedWishMinimumCount))）",
                source: source
            )
        case .condition:
            guard let groupID = draft.conditionGroupID,
                  let goodsTypeID = draft.conditionGoodsTypeID
            else {
                return nil
            }
            let groupName = appState.oshiGroups.first { $0.id == groupID }?.name ?? "グループ未設定"
            let goodsTypeName = appState.goodsTypes.first { $0.id == goodsTypeID }?.name ?? "種別未設定"
            let memberText = conditionMemberSummary()
            let tagText = draft.conditionTagNames.isEmpty ? "タグ指定なし" : draft.conditionTagNames.map { "#\($0)" }.joined(separator: " / ")
            let amountText = draft.usesConditionLogicChoice ? draft.wishLogic.displayName : "\(draft.conditionQuantity)点"
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "条件",
                detail: "\(groupName) / \(memberText) / \(goodsTypeName) / \(tagText) / \(amountText)",
                source: source
            )
        case .cash:
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "定価",
                detail: draft.cashPricingMode == .specifiedAmount ? "¥\(draft.cashAmount.formatted())" : "定価",
                source: source
            )
        }
    }

    private func conditionMemberSummary() -> String {
        let selectedMembers = appState.oshiCharacters.filter { draft.conditionMemberIDs.contains($0.id) }
        guard !selectedMembers.isEmpty else {
            return "メンバー指定なし"
        }
        let names = selectedMembers.prefix(3).map(\.name).joined(separator: "・")
        let suffix = selectedMembers.count > 3 ? " 他\(selectedMembers.count - 3)人" : ""
        return draft.excludesSelectedConditionMembers ? "\(names)\(suffix)以外" : "\(names)\(suffix)"
    }
}
