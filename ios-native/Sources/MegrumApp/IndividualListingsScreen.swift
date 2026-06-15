import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var headerTitle: String = "個別募集"
    var headerAccessory: AnyView?
    var showsHeader = true
    var initialEditorOptionKind: IndividualListingOptionKind? = nil
    var initialEditorStep: IndividualListingEditorStep = .haves
    var initiallyPresentsEditor = false
    @State private var editorRoute: IndividualListingEditorRoute?
    @State private var locallyEditedListings: [UUID: IndividualListing] = [:]
    @State private var didPresentInitialEditor = false
    @State private var pendingDeleteListing: IndividualListing?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            IndividualListingsContent(
                headerTitle: headerTitle,
                headerAccessory: headerAccessory,
                showsHeader: showsHeader,
                isLoading: appState.isLoadingIndividualListings,
                listings: displayedListings,
                inventoryByID: inventoryByID,
                wishByID: wishByID,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                goodsTypes: appState.goodsTypes,
                viewerID: appState.viewer?.id,
                onEdit: { listing in
                    editorRoute = .edit(listing, initialStep: .haves)
                },
                onAddCondition: { listing in
                    editorRoute = .edit(listing, initialStep: .options)
                },
                onDelete: { listing in
                    pendingDeleteListing = listing
                }
            )
            .refreshable {
                locallyEditedListings.removeAll()
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            AddIndividualListingButton(title: "募集を追加") {
                editorRoute = .create(optionKind: nil)
            }
            .padding(.trailing, 18)
            .padding(.bottom, FloatingActionLayoutMetrics.bottomGapAboveFooter)
        }
        .task {
            if appState.listings.isEmpty {
                await appState.loadIndividualListings()
            }
            await loadChoicesIfNeeded()
            presentInitialEditorIfNeeded()
        }
        .onAppear {
            presentInitialEditorIfNeeded()
        }
        .onChange(of: initialEditorOptionKind?.rawValue, initial: true) { _, _ in
            presentInitialEditorIfNeeded()
        }
        .individualListingEditorPresentation(item: $editorRoute) { route in
            NavigationStack {
                switch route {
                case .create(let optionKind):
                    IndividualListingEditorSheet(
                        appState: appState,
                        initialOptionKind: optionKind,
                        initialStep: initialEditorStep
                    )
                case .edit(let listing, let initialStep):
                    IndividualListingEditorSheet(appState: appState, editing: listing, initialStep: initialStep) { updated in
                        locallyEditedListings[updated.id] = updated
                    }
                }
            }
        }
        .confirmationDialog("この交換条件を削除しますか？", isPresented: Binding(
            get: { pendingDeleteListing != nil },
            set: { if !$0 { pendingDeleteListing = nil } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let listing = pendingDeleteListing {
                    archiveListing(listing)
                }
                pendingDeleteListing = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteListing = nil
            }
        } message: {
            Text("削除すると個別募集の一覧には表示されなくなります。")
        }
    }

    private var displayedListings: [IndividualListing] {
        appState.listings.map { listing in
            locallyEditedListings[listing.id] ?? listing
        }
    }

    private var inventoryByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
    }

    private var wishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    private func loadChoicesIfNeeded() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    private func presentInitialEditorIfNeeded() {
        guard !didPresentInitialEditor, initiallyPresentsEditor || initialEditorOptionKind != nil || initialEditorStep != .haves else {
            return
        }
        didPresentInitialEditor = true
        editorRoute = .create(optionKind: initialEditorOptionKind)
    }

    private func archiveListing(_ listing: IndividualListing) {
        Task {
            let deleted = await appState.archiveIndividualListing(listing.id)
            if deleted {
                locallyEditedListings.removeValue(forKey: listing.id)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func individualListingEditorPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

private enum IndividualListingEditorRoute: Identifiable {
    case create(optionKind: IndividualListingOptionKind?)
    case edit(IndividualListing, initialStep: IndividualListingEditorStep)

    var id: String {
        switch self {
        case .create(let optionKind):
            "create-\(optionKind?.rawValue ?? "default")"
        case .edit(let listing, let initialStep):
            "edit-\(listing.id.uuidString)-\(initialStep.rawValue)"
        }
    }
}

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: IndividualListingDraft
    @State private var step: IndividualListingEditorStep
    @State private var havesTab: IndividualListingHavesStep.Tab = .goods
    @State private var stagedOptionSummaries: [IndividualListingOptionReviewItem] = []
    @State private var showsOptionReview = false

    init(
        appState: MegrumAppState,
        preselectedWishID: UUID? = nil,
        initialOptionKind: IndividualListingOptionKind? = nil,
        initialStep: IndividualListingEditorStep = .haves
    ) {
        self.appState = appState
        self.onLocalEditSaved = nil
        var draft = IndividualListingDraft(mode: .create(preselectedWishID: preselectedWishID))
        if let initialOptionKind {
            draft.setOptionKind(initialOptionKind)
        }
        self._draft = State(initialValue: draft)
        self._step = State(initialValue: initialOptionKind == nil ? initialStep : .options)
    }

    init(
        appState: MegrumAppState,
        editing listing: IndividualListing,
        initialStep: IndividualListingEditorStep = .haves,
        onLocalEditSaved: @escaping (IndividualListing) -> Void
    ) {
        self.appState = appState
        self.onLocalEditSaved = onLocalEditSaved
        self._draft = State(initialValue: IndividualListingDraft(mode: .edit(listing)))
        self._step = State(initialValue: initialStep)
    }

    var body: some View {
        IndividualListingEditorContent(
            draft: $draft,
            havesTab: $havesTab,
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
                haveLogic: $draft.haveLogic,
                wishLogic: $draft.wishLogic,
                usesConditionLogicChoice: draft.usesConditionLogicChoice,
                isDisabled: stepValidationMessage != nil || isSaving,
                isSaving: isSaving,
                onBack: goBack,
                onAddOption: addCurrentOption,
                onPrimary: primaryAction
            )
        }
        .sheet(isPresented: $showsOptionReview) {
            IndividualListingOptionReviewSheet(items: optionReviewItems)
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
    }

    private func toggleHave(_ item: GoodsItem) {
        draft.toggleHave(item.id, maxQuantity: draft.maxHaveQuantity(for: item))
    }

    private func toggleWish(_ item: WishItem) {
        draft.toggleWish(item.id)
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

    private var validationMessage: String? {
        draft.validationMessage(inventory: appState.inventory, wishes: appState.wishes)
    }

    private var stepValidationMessage: String? {
        switch step {
        case .haves:
            if havesTab == .cash {
                return draft.cashAmount <= 0 ? "定価を入力してください" : nil
            }
            return draft.selectedHaveIDs.isEmpty ? "譲るものを選択してください" : nil
        case .options:
            switch draft.optionKind {
            case .wish:
                return draft.selectedWishIDs.isEmpty ? "受け取れる候補を選択してください" : nil
            case .condition:
                return draft.conditionGroupID == nil || draft.conditionGoodsTypeID == nil ? "グループとグッズ種別を選択してください" : nil
            case .cash:
                return draft.cashAmount <= 0 ? "定価を入力してください" : nil
            }
        case .exchange:
            return validationMessage
        }
    }

    private var isSaving: Bool {
        switch draft.mode {
        case .create:
            return appState.isCreatingIndividualListing
        case .edit(let listing):
            return appState.updatingIndividualListingID == listing.id
        }
    }

    private func save() async {
        guard let input = draft.createInput(inventory: appState.inventory, wishes: appState.wishes) else {
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
                dismiss()
            }
            return
        }
        let saved = await appState.createIndividualListing(
            input
        )
        if saved {
            dismiss()
        }
    }

    private func goBack() {
        switch step {
        case .haves:
            dismiss()
        case .options:
            withAnimation(.smooth(duration: 0.2)) {
                step = .haves
            }
        case .exchange:
            withAnimation(.smooth(duration: 0.2)) {
                step = .options
            }
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
        if let current = makeCurrentOptionReviewItem(title: items.isEmpty ? "編集中の選択肢" : "編集中") {
            items.append(current)
        }
        return items
    }

    private func makeCurrentOptionReviewItem(title: String) -> IndividualListingOptionReviewItem? {
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
                detail: "\(wishTitles)（\(draft.wishLogic.displayName)）"
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
                detail: "\(groupName) / \(memberText) / \(goodsTypeName) / \(tagText) / \(amountText)"
            )
        case .cash:
            guard draft.cashAmount > 0 else {
                return nil
            }
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "定価",
                detail: "¥\(draft.cashAmount.formatted())"
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
