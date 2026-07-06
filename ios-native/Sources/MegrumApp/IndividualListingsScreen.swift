import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) private var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) private var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) private var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) private var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) private var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) private var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    var headerTitle: String = "個別募集"
    var headerAccessory: AnyView?
    var showsHeader = true
    var onScrollContentTopChange: ((CGFloat) -> Void)? = nil
    var onSwipeBackFromFirst: (() -> Void)? = nil
    var initialEditorOptionKind: IndividualListingOptionKind? = nil
    var initialEditorStep: IndividualListingEditorStep = .haves
    var initiallyPresentsEditor = false
    @State private var presentationState = IndividualListingsPresentationState()
    /// 編集/作成シートのキーボードで壊れたスクロール位置を閉了時に復元する。
    @State private var listingScrollResetToken = 0
    @State private var sharePromptContext: GoodsSharePostContext?
    @State private var isPreparingSharePost = false
    @State private var sharePostErrorMessage: String?
    @State private var selectedListingIDs: Set<UUID> = []
    @State private var isConfirmingBulkListingDelete = false
    #if os(iOS)
    @State private var shareActivityPayload: GoodsSharePostPayload?
    #endif

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
                isSelectionMode: isListingSelectionMode,
                selectedListingIDs: selectedListingIDs,
                onEditOffer: { listing in
                    presentationState.openEdit(listing, initialStep: .haves)
                },
                onAddCondition: { listing in
                    presentationState.openEdit(listing, initialStep: .options)
                },
                onEditExchangeCondition: { listing in
                    presentationState.openEdit(listing, initialStep: .exchange)
                },
                onShare: handleListingShare,
                onDelete: { listing in
                    presentationState.requestDelete(listing)
                },
                onBeginSelection: beginListingSelection,
                onToggleSelection: toggleListingSelection,
                onScrollContentTopChange: onScrollContentTopChange,
                onSwipeBackFromFirst: onSwipeBackFromFirst,
                scrollResetToken: listingScrollResetToken
            )
            .refreshable {
                presentationState.clearLocalEdits()
                selectedListingIDs = []
                await appState.loadIndividualListings()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            if !isListingSelectionMode {
                AddIndividualListingButton(title: "募集を追加") {
                    openCreateEditor(optionKind: nil)
                }
                // マイグッズ/ほしいものの右下フローティングと同じ余白に統一する
                .padding(.trailing, FloatingActionLayoutMetrics.leadingPadding)
                .padding(.bottom, FloatingActionLayoutMetrics.addButtonBottomPadding)
            }

            if isListingSelectionMode {
                IndividualListingSelectionFooter(
                    selectedCount: selectedListingIDs.count,
                    onDelete: requestBulkListingDelete,
                    onCancel: cancelListingSelection
                )
                .padding(.horizontal, GoodsSelectionFooterMetrics.horizontalPadding)
                .padding(.bottom, GoodsSelectionFooterMetrics.bottomPadding)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(6)
            }

            if let sharePromptContext {
                GoodsSharePromptOverlay(
                    context: sharePromptContext,
                    isPreparing: isPreparingSharePost,
                    errorMessage: sharePostErrorMessage,
                    onDismiss: dismissSharePrompt,
                    onShare: startGoodsSharePost
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .zIndex(20)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        // 作成/編集シートのキーボードで背後の一覧がズレたままになるのを防ぐ。
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        .onChange(of: displayedListings.map(\.id), initial: true) { _, ids in
            reconcileListingSelection(with: ids)
        }
        .individualListingEditorPresentation(
            item: $presentationState.editorRoute,
            onDismiss: { listingScrollResetToken += 1 }
        ) { route in
            NavigationStack {
                switch route {
                case .create(let optionKind):
                    IndividualListingEditorSheet(
                        appState: appState,
                        initialOptionKind: optionKind,
                        defaultExchangeSummary: defaultExchangeSettings.makeListingExchangeSummary(),
                        initialStep: initialEditorStep,
                        onSaved: { presentationState.closeEditor() },
                        onCreatedListing: handleCreatedListingShare
                    )
                case .edit(let listing, let initialStep):
                    IndividualListingEditorSheet(
                        appState: appState,
                        editing: listing,
                        initialStep: initialStep,
                        onSaved: { presentationState.closeEditor() }
                    ) { updated in
                        presentationState.recordEdited(updated)
                    }
                }
            }
        }
        .confirmationDialog("この個別募集を本当に削除しますか？", isPresented: Binding(
            get: { presentationState.hasPendingDelete },
            set: { if !$0 { presentationState.clearPendingDelete() } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let listing = presentationState.pendingDeleteListing {
                    archiveListing(listing)
                }
                presentationState.clearPendingDelete()
            }
            Button("キャンセル", role: .cancel) {
                presentationState.clearPendingDelete()
            }
        } message: {
            Text("削除すると個別募集の一覧には表示されなくなります。")
        }
        .confirmationDialog("選択した個別募集を削除しますか？", isPresented: $isConfirmingBulkListingDelete, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                archiveSelectedListings()
            }
            Button("キャンセル", role: .cancel) {
                isConfirmingBulkListingDelete = false
            }
        } message: {
            Text("\(selectedListingIDs.count)件の個別募集を一覧から削除します。")
        }
        .sheet(isPresented: $presentationState.showsMegrumPlusUpsell) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
        }
        #if os(iOS)
        .sheet(item: $shareActivityPayload, content: GoodsShareActivitySheet.init)
        #endif
        .animation(.spring(response: 0.30, dampingFraction: 0.86), value: sharePromptContext?.id)
    }

    private var displayedListings: [IndividualListing] {
        presentationState.displayedListings(appState.listings)
    }

    private var inventoryByID: [UUID: GoodsItem] {
        Dictionary(uniqueKeysWithValues: appState.inventory.map { ($0.id, $0) })
    }

    private var wishByID: [UUID: WishItem] {
        Dictionary(uniqueKeysWithValues: appState.wishes.map { ($0.id, $0) })
    }

    private var defaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
    }

    private var isListingSelectionMode: Bool {
        !selectedListingIDs.isEmpty
    }

    private func loadChoicesIfNeeded() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        // 条件のグループ選択シートで「自分の推し」を最初に出すために必要。
        if appState.userOshiSelections.isEmpty {
            await appState.loadUserOshiSelections()
        }
    }

    private func presentInitialEditorIfNeeded() {
        guard presentationState.shouldPresentInitialEditor(
            initiallyPresentsEditor: initiallyPresentsEditor,
            initialEditorOptionKind: initialEditorOptionKind,
            initialEditorStep: initialEditorStep
        ) else {
            return
        }
        openCreateEditor(optionKind: initialEditorOptionKind)
    }

    private func openCreateEditor(optionKind: IndividualListingOptionKind?) {
        presentationState.openCreateEditor(
            optionKind: optionKind,
            listings: displayedListings,
            subscriptionState: appState.subscriptionState
        )
    }

    private func archiveListing(_ listing: IndividualListing) {
        Task {
            let deleted = await appState.archiveIndividualListing(listing.id)
            if deleted {
                presentationState.removeLocalEdit(for: listing.id)
                selectedListingIDs.remove(listing.id)
            }
        }
    }

    private func handleCreatedListingShare(_ listing: IndividualListing) {
        handleListingShare(listing)
    }

    private func handleListingShare(_ listing: IndividualListing) {
        Task { @MainActor in
            if !appState.hasLoadedPaymentSettings {
                await appState.loadPaymentSettings(reportsFailure: false)
            }
            presentListingSharePrompt(listing)
        }
    }

    private func presentListingSharePrompt(_ listing: IndividualListing) {
        sharePostErrorMessage = nil
        isPreparingSharePost = false
        let displayName = viewerDisplayNameForSharePost()
        let snapshot = IndividualListingShareSnapshotFactory.make(
            listing: listing,
            displayName: displayName,
            inventory: appState.inventory,
            wishes: appState.wishes,
            groups: appState.oshiGroups,
            goodsTypes: appState.goodsTypes,
            paymentMethodsText: paymentMethodsTextForSharePost()
        )
        sharePromptContext = GoodsSharePostContext(
            kind: .individualListing,
            items: [],
            displayName: displayName,
            listingSnapshot: snapshot,
            promptTitle: "Xで投稿",
            promptDescription: "この個別募集を画像と文面にしてXで周知できます。",
            shareButtonTitle: "Xで個別募集をポストする"
        )
    }

    private func beginListingSelection(_ listing: IndividualListing) {
        guard listing.ownerID == appState.viewer?.id else {
            return
        }
        selectedListingIDs = [listing.id]
    }

    private func toggleListingSelection(_ listing: IndividualListing) {
        guard listing.ownerID == appState.viewer?.id else {
            return
        }
        if selectedListingIDs.contains(listing.id) {
            selectedListingIDs.remove(listing.id)
        } else {
            selectedListingIDs.insert(listing.id)
        }
    }

    private func cancelListingSelection() {
        selectedListingIDs = []
        isConfirmingBulkListingDelete = false
    }

    private func requestBulkListingDelete() {
        guard !selectedListingIDs.isEmpty else {
            return
        }
        isConfirmingBulkListingDelete = true
    }

    private func archiveSelectedListings() {
        let targetIDs = selectedListingIDs
        isConfirmingBulkListingDelete = false
        Task { @MainActor in
            var removedIDs = Set<UUID>()
            for listingID in targetIDs {
                if await appState.archiveIndividualListing(listingID) {
                    presentationState.removeLocalEdit(for: listingID)
                    removedIDs.insert(listingID)
                }
            }
            selectedListingIDs.subtract(removedIDs)
        }
    }

    private func reconcileListingSelection(with listingIDs: [UUID]) {
        selectedListingIDs.formIntersection(Set(listingIDs))
        if selectedListingIDs.isEmpty {
            isConfirmingBulkListingDelete = false
        }
    }

    private func dismissSharePrompt() {
        guard !isPreparingSharePost else {
            return
        }
        sharePromptContext = nil
        sharePostErrorMessage = nil
    }

    #if os(iOS)
    private func startGoodsSharePost() {
        guard let sharePromptContext, !isPreparingSharePost else {
            return
        }
        isPreparingSharePost = true
        sharePostErrorMessage = nil

        Task { @MainActor in
            do {
                shareActivityPayload = try await GoodsSharePostRenderer.payload(for: sharePromptContext)
                isPreparingSharePost = false
            } catch {
                isPreparingSharePost = false
                sharePostErrorMessage = "ポスト画像を作成できませんでした。時間をおいてもう一度お試しください。"
            }
        }
    }
    #else
    private func startGoodsSharePost() {
        sharePostErrorMessage = "この端末ではXへの共有を利用できません。"
    }
    #endif

    private func viewerDisplayNameForSharePost() -> String {
        [
            appState.viewer?.displayName,
            appState.viewer?.handle
        ]
        .compactMap(normalizedShareDisplayName)
        .first ?? "Megrumユーザー"
    }

    private func normalizedShareDisplayName(_ value: String?) -> String? {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    private func paymentMethodsTextForSharePost() -> String {
        GoodsSharePostTextBuilder.paymentMethodsText(
            methods: PaymentSettingsResolver.methods(
                settings: appState.paymentSettings,
                viewer: appState.viewer
            ),
            otherNote: PaymentSettingsResolver.otherNote(
                settings: appState.paymentSettings,
                viewer: appState.viewer
            )
        )
    }
}

private extension View {
    @ViewBuilder
    func individualListingEditorPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        #else
        sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }
}

enum IndividualListingEditorRoute: Identifiable, Equatable {
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
