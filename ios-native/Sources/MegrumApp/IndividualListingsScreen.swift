import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var headerAccessory: AnyView?
    var initialEditorOptionKind: IndividualListingOptionKind? = nil
    var initialEditorStep: IndividualListingEditorStep = .haves
    var initiallyPresentsEditor = false
    @State private var editorRoute: IndividualListingEditorRoute?
    @State private var locallyEditedListings: [UUID: IndividualListing] = [:]
    @State private var selectedStatus: IndividualListingStatus = .active
    @State private var didPresentInitialEditor = false

    var body: some View {
        ZStack(alignment: .bottom) {
            IndividualListingsContent(
                headerAccessory: headerAccessory,
                selectedStatus: $selectedStatus,
                listingCountsByStatus: listingCountsByStatus,
                isLoading: appState.isLoadingIndividualListings,
                listings: filteredListings,
                inventoryByID: inventoryByID,
                wishByID: wishByID,
                viewerID: appState.viewer?.id,
                onEdit: { listing in
                    editorRoute = .edit(listing)
                }
            )
            .refreshable {
                locallyEditedListings.removeAll()
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            AddIndividualListingButton(title: "個別募集を追加") {
                editorRoute = .create(optionKind: nil)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 14)
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
                case .edit(let listing):
                    IndividualListingEditorSheet(appState: appState, editing: listing) { updated in
                        locallyEditedListings[updated.id] = updated
                    }
                }
            }
        }
    }

    private var displayedListings: [IndividualListing] {
        appState.listings.map { listing in
            locallyEditedListings[listing.id] ?? listing
        }
    }

    private var filteredListings: [IndividualListing] {
        displayedListings.filter { $0.status == selectedStatus }
    }

    private var listingCountsByStatus: [IndividualListingStatus: Int] {
        Dictionary(grouping: displayedListings, by: \.status).mapValues(\.count)
    }

    private var inventoryByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
    }

    private var wishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    private func loadChoicesIfNeeded() async {
        if appState.oshiGroups.isEmpty {
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
    case edit(IndividualListing)

    var id: String {
        switch self {
        case .create(let optionKind):
            "create-\(optionKind?.rawValue ?? "default")"
        case .edit(let listing):
            "edit-\(listing.id.uuidString)"
        }
    }
}

struct IndividualListingEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var onLocalEditSaved: ((IndividualListing) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: IndividualListingDraft
    @State private var step: IndividualListingEditorStep

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

    init(appState: MegrumAppState, editing listing: IndividualListing, onLocalEditSaved: @escaping (IndividualListing) -> Void) {
        self.appState = appState
        self.onLocalEditSaved = onLocalEditSaved
        self._draft = State(initialValue: IndividualListingDraft(mode: .edit(listing)))
        self._step = State(initialValue: .haves)
    }

    var body: some View {
        IndividualListingEditorContent(
            draft: $draft,
            step: step,
            inventory: appState.inventory,
            wishes: appState.wishes,
            groups: appState.oshiGroups,
            goodsTypes: appState.goodsTypes,
            stepValidationMessage: stepValidationMessage,
            onBack: goBack,
            onCash: selectCashOption,
            onToggleHave: toggleHave,
            onToggleWish: toggleWish
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            IndividualListingEditorBottomBar(
                step: step,
                selectedCount: draft.selectedHaveIDs.count,
                isDisabled: stepValidationMessage != nil || isSaving,
                isSaving: isSaving,
                onBack: goBack,
                onPrimary: primaryAction
            )
        }
        .onAppear {
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
            seedDraftDefaultsIfNeeded()
        }
        .onChange(of: appState.oshiGroups.map(\.id)) { _, _ in
            draft.ensureDefaultCondition(
                groupID: appState.oshiGroups.first?.id,
                goodsTypeID: appState.goodsTypes.first?.id
            )
        }
    }

    private func selectCashOption() {
        draft.setOptionKind(.cash)
        withAnimation(.smooth(duration: 0.2)) {
            step = .options
        }
    }

    private func toggleHave(_ item: GoodsItem) {
        draft.toggleHave(item.id, maxQuantity: item.quantity)
    }

    private func toggleWish(_ item: WishItem) {
        draft.toggleWish(item.id)
    }

    private var validationMessage: String? {
        draft.validationMessage(inventory: appState.inventory, wishes: appState.wishes)
    }

    private var stepValidationMessage: String? {
        switch step {
        case .haves:
            draft.selectedHaveIDs.isEmpty ? "譲るものを選択してください" : nil
        case .options:
            switch draft.optionKind {
            case .wish:
                draft.selectedWishIDs.isEmpty ? "受け取れる候補を選択してください" : nil
            case .condition:
                draft.conditionGroupID == nil || draft.conditionGoodsTypeID == nil ? "グループとグッズ種別を選択してください" : nil
            case .cash:
                draft.cashAmount <= 0 ? "定価を入力してください" : nil
            }
        case .exchange:
            validationMessage
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

    private func seedDraftDefaultsIfNeeded() {
        if step != .haves, draft.selectedHaveIDs.isEmpty, let firstHave = appState.inventory.first {
            draft.toggleHave(firstHave.id, maxQuantity: firstHave.quantity)
        }
        if step == .exchange, draft.optionKind == .wish, draft.selectedWishIDs.isEmpty, let firstWish = appState.wishes.first {
            draft.toggleWish(firstWish.id)
        }
    }
}
