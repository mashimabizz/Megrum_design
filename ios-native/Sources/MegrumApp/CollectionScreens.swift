import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCollectionFilter: Equatable {
    var groupID: UUID?
    var goodsTypeID: UUID?
    var tagNames: Set<String> = []

    var isActive: Bool {
        groupID != nil || goodsTypeID != nil || !tagNames.isEmpty
    }

    var activeCount: Int {
        var count = 0
        if groupID != nil { count += 1 }
        if goodsTypeID != nil { count += 1 }
        count += tagNames.count
        return count
    }

    func matches(_ item: GoodsItem) -> Bool {
        if let groupID, item.groupID != groupID {
            return false
        }
        if let goodsTypeID, item.goodsTypeID != goodsTypeID {
            return false
        }
        if !tagNames.isEmpty {
            let itemTagNames = Set(item.tags.map(\.name))
            if !tagNames.isSubset(of: itemTagNames) {
                return false
            }
        }
        return true
    }
}

struct GoodsCollectionFilterChoices {
    static func groups(items: [GoodsItem], allGroups: [OshiGroup]) -> [OshiGroup] {
        let usedGroupIDs = Set(items.compactMap(\.groupID))
        return allGroups.filter { usedGroupIDs.contains($0.id) }
    }

    static func goodsTypes(items: [GoodsItem], allGoodsTypes: [GoodsType]) -> [GoodsType] {
        let usedGoodsTypeIDs = Set(items.compactMap(\.goodsTypeID))
        return allGoodsTypes.filter { usedGoodsTypeIDs.contains($0.id) }
    }

    static func tagNames(
        items: [GoodsItem],
        selectedGroupID: UUID?,
        selectedGoodsTypeID: UUID?,
        limit: Int = 20
    ) -> [String] {
        let structuralFilter = GoodsCollectionFilter(
            groupID: selectedGroupID,
            goodsTypeID: selectedGoodsTypeID
        )
        let names = items
            .filter(structuralFilter.matches)
            .flatMap { $0.tags.map(\.name) }
        return TagNameNormalizer.uniqueSorted(names, limit: limit)
    }
}

enum CollectionScreenLayoutMetrics {
    static let mainStackSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 14
    static let headerAccessoryVerticalPadding: CGFloat = 2
    static let filterBarSpacing: CGFloat = 6
    static let filterRowLabelWidth: CGFloat = 64
    static let filterRowChipSpacing: CGFloat = 7
    static let filterChipHeight: CGFloat = 32
    static let filterChipHorizontalPadding: CGFloat = 12
    static let filterChipFontSize: CGFloat = 12.5
    static let filterChipGlassSelectedOpacity: Double = 0.22
    static let filterChipGlassIdleOpacity: Double = 0.10
}

struct GoodsCollectionScreen: View {
    var title: String
    var subtitle: String
    var items: [GoodsItem]
    var showsAddButton: Bool = false
    var appState: MegrumAppState?
    var entryKind: GoodsEntryKind = .inventory
    var headerAccessory: AnyView?
    var showsHeader = true
    var showsColumnToggle = true
    @State private var columns = GoodsGridLayout.minimumColumns
    @State private var editorRoute: GoodsEditorRoute?
    @State private var isShowingUnavailableAlert = false
    @State private var listingSeedWish: GoodsItem?
    @State private var selectedGroupID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var selectedTagNames: Set<String> = []
    @State private var selectedInventoryStatus: GoodsEntryStatus = .active
    @State private var quickActionItem: GoodsItem?
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var bulkTagRoute: GoodsBulkTagRoute?
    @State private var pendingSingleDeleteItem: GoodsItem?
    @State private var isConfirmingBulkDelete = false

    private static let inventoryStatuses: [GoodsEntryStatus] = [.active, .keep, .traded]

    private var activeFilter: GoodsCollectionFilter {
        GoodsCollectionFilter(groupID: selectedGroupID, goodsTypeID: selectedGoodsTypeID, tagNames: selectedTagNames)
    }

    private func statusFilteredItems(for inventoryStatus: GoodsEntryStatus? = nil) -> [GoodsItem] {
        guard entryKind == .inventory else {
            return items
        }
        let inventoryStatus = inventoryStatus ?? selectedInventoryStatus
        return items.filter { item in
            switch inventoryStatus {
            case .active:
                return item.status == nil || item.status == .active || item.status == .reserved
            case .keep:
                return item.status == .keep
            case .traded:
                return item.status == .traded
            case .reserved:
                return item.status == .reserved
            case .archived:
                return item.status == .archived
            }
        }
    }

    private var filteredItems: [GoodsItem] {
        filteredItems(for: nil)
    }

    private func filteredItems(for inventoryStatus: GoodsEntryStatus?) -> [GoodsItem] {
        statusFilteredItems(for: inventoryStatus).filter(activeFilter.matches)
    }

    private var hasActiveFilters: Bool {
        activeFilter.isActive
    }

    private var isSelectionMode: Bool {
        !selectedItemIDs.isEmpty
    }

    private var selectedItems: [GoodsItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    private func supportsInventoryManagementActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        entryKind == .inventory && appState != nil && !isReadOnlyInventoryPage(inventoryStatus)
    }

    private func supportsOwnedItemQuickActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        appState != nil && (entryKind == .wish || (entryKind == .inventory && !isReadOnlyInventoryPage(inventoryStatus)))
    }

    private func supportsSystemCardActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        appState != nil && entryKind == .inventory && !isReadOnlyInventoryPage(inventoryStatus)
    }

    private func isReadOnlyInventoryPage(_ inventoryStatus: GoodsEntryStatus?) -> Bool {
        entryKind == .inventory && (inventoryStatus ?? selectedInventoryStatus) == .traded
    }

    private var filterBaseItems: [GoodsItem] {
        statusFilteredItems()
    }

    private var availableGroups: [OshiGroup] {
        guard let appState else {
            return []
        }
        return GoodsCollectionFilterChoices.groups(
            items: filterBaseItems,
            allGroups: appState.oshiGroups
        )
    }

    private var availableGoodsTypes: [GoodsType] {
        guard let appState else {
            return []
        }
        return GoodsCollectionFilterChoices.goodsTypes(
            items: filterBaseItems,
            allGoodsTypes: appState.goodsTypes
        )
    }

    private var availableTagNames: [String] {
        GoodsCollectionFilterChoices.tagNames(
            items: filterBaseItems,
            selectedGroupID: selectedGroupID,
            selectedGoodsTypeID: selectedGoodsTypeID
        )
    }

    private var inventoryStatusCounts: [GoodsEntryStatus: Int] {
        Dictionary(uniqueKeysWithValues: Self.inventoryStatuses.map { status in
            let count = items.filter { item in
                switch status {
                case .active:
                    return item.status == nil || item.status == .active || item.status == .reserved
                case .keep:
                    return item.status == .keep
                case .traded:
                    return item.status == .traded
                case .reserved, .archived:
                    return false
                }
            }.count
            return (status, count)
        })
    }

    private var selectedInventoryStatusTitle: String {
        selectedInventoryStatus.inventoryTabTitle
    }

    private var isShowingLoadingState: Bool {
        appState?.isLoading == true && items.isEmpty
    }

    private var emptyMessageTitle: String {
        emptyMessageTitle(for: nil)
    }

    private func emptyMessageTitle(for inventoryStatus: GoodsEntryStatus?) -> String {
        if hasActiveFilters {
            return "条件に合うグッズがありません"
        }
        if title == "個別募集" {
            return "個別募集はまだありません"
        }
        switch entryKind {
        case .inventory:
            switch inventoryStatus ?? selectedInventoryStatus {
            case .active, .reserved:
                return "譲る候補はまだありません"
            case .keep:
                return "自分用キープはまだありません"
            case .traded:
                return "過去に譲ったグッズはまだありません"
            case .archived:
                return "非表示のグッズはありません"
            }
        case .wish:
            return "Wishはまだありません"
        }
    }

    private var emptyMessageDetail: String {
        emptyMessageDetail(for: nil)
    }

    private func emptyMessageDetail(for inventoryStatus: GoodsEntryStatus?) -> String {
        if hasActiveFilters {
            return "フィルターを変えると表示されることがあります。"
        }
        if title == "個別募集" {
            return "条件を指定した募集は、Wishから作成できます。"
        }
        switch entryKind {
        case .inventory:
            switch inventoryStatus ?? selectedInventoryStatus {
            case .active, .reserved:
                return "譲る候補を登録すると、検索や打診に使えるようになります。"
            case .keep:
                return "交換に出さない手元用グッズはここで管理できます。"
            case .traded:
                return "譲渡済みのグッズはここにまとまります。"
            case .archived:
                return "非表示にしたグッズは通常の一覧から外れます。"
            }
        case .wish:
            return "探したいグッズを登録すると、候補探しに使えるようになります。"
        }
    }

    private var emptyMessageSystemImage: String {
        emptyMessageSystemImage(for: nil)
    }

    private func emptyMessageSystemImage(for inventoryStatus: GoodsEntryStatus?) -> String {
        if hasActiveFilters {
            return "line.3.horizontal.decrease.circle"
        }
        if title == "個別募集" {
            return "rectangle.stack.badge.plus"
        }
        switch entryKind {
        case .inventory:
            switch inventoryStatus ?? selectedInventoryStatus {
            case .active, .reserved:
                return "shippingbox"
            case .keep:
                return "archivebox"
            case .traded:
                return "checkmark.seal"
            case .archived:
                return "eye.slash"
            }
        case .wish:
            return "heart"
        }
    }

    private var emptyMessageActionTitle: String? {
        if hasActiveFilters {
            return "フィルターをクリア"
        }
        return showsAddButton ? addButtonLabel : nil
    }

    private var emptyMessageAction: (() -> Void)? {
        guard emptyMessageActionTitle != nil else {
            return nil
        }
        if hasActiveFilters {
            return { resetFilters() }
        }
        return { openAddForm() }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            collectionContent

            GoodsCollectionFloatingControls(
                showsAddButton: showsAddButton,
                addButtonLabel: addButtonLabel,
                addButtonHint: addButtonHint,
                isSelectionMode: isSelectionMode,
                quickActionItem: quickActionItem,
                quickActions: GoodsQuickActionKind.actions(for: entryKind),
                selectedCount: selectedItemIDs.count,
                onAdd: openAddForm,
                onDismissQuickAction: {
                    quickActionItem = nil
                },
                onQuickAction: performQuickAction,
                onBulkTag: {
                    bulkTagRoute = GoodsBulkTagRoute(itemIDs: selectedItemIDs)
                },
                onBulkDelete: {
                    isConfirmingBulkDelete = true
                },
                onCancelSelection: {
                    selectedItemIDs = []
                }
            )
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: quickActionItem?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectedItemIDs)
        .sheet(item: $editorRoute) { route in
            if let appState {
                NavigationStack {
                    GoodsEditorSheet(
                        appState: appState,
                        route: route
                    )
                }
            }
        }
        .sheet(item: $listingSeedWish) { item in
            if let appState {
                NavigationStack {
                    IndividualListingEditorSheet(
                        appState: appState,
                        preselectedWishID: item.id
                    )
                }
            }
        }
        .sheet(item: $bulkTagRoute) { route in
            GoodsBulkTagSheet(
                selectedCount: route.itemIDs.count,
                candidateNames: bulkTagCandidateNames(for: route.itemIDs),
                previewItemsByTag: bulkTagPreviewItemsByTag(for: route.itemIDs)
            ) { tagName in
                applyBulkTag(tagName, to: route.itemIDs)
            }
        }
        .alert("追加できません", isPresented: $isShowingUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("データ保存の準備がまだ整っていません。")
        }
        .confirmationDialog("削除しますか？", isPresented: Binding(
            get: { pendingSingleDeleteItem != nil },
            set: { if !$0 { pendingSingleDeleteItem = nil } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let pendingSingleDeleteItem {
                    deleteItem(pendingSingleDeleteItem)
                }
                pendingSingleDeleteItem = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingSingleDeleteItem = nil
            }
        } message: {
            if let pendingSingleDeleteItem {
                Text("「\(pendingSingleDeleteItem.title)」を削除します。")
            }
        }
        .confirmationDialog("\(selectedItemIDs.count)件を削除しますか？", isPresented: $isConfirmingBulkDelete, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                deleteSelectedItems()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("選択中のグッズを削除します。")
        }
        .task {
            await loadFilterChoicesIfNeeded()
        }
        .onChange(of: selectedGroupID) { _, _ in
            reconcileSelectedTags()
        }
        .onChange(of: selectedGoodsTypeID) { _, _ in
            reconcileSelectedTags()
        }
        .onChange(of: selectedInventoryStatus) { _, _ in
            quickActionItem = nil
            selectedItemIDs = []
            reconcileSelectedFilters()
        }
        .onChange(of: items.map(\.id)) { _, _ in
            reconcileSelectedFilters()
        }
        .onChange(of: filteredItems.map(\.id)) { _, visibleIDs in
            selectedItemIDs.formIntersection(Set(visibleIDs))
        }
    }

    @ViewBuilder
    private var collectionContent: some View {
        if entryKind == .inventory {
            VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                collectionTopChrome
                    .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
                    .padding(.top, CollectionScreenLayoutMetrics.topPadding)

                TabView(selection: $selectedInventoryStatus) {
                    ForEach(Self.inventoryStatuses, id: \.self) { status in
                        collectionPageScroll(status: status)
                            .tag(status)
                    }
                }
                .megrumPageTabViewStyle()
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()
        } else {
            collectionPageScroll(status: nil, includesTopChrome: showsHeader)
                .background(MegrumTheme.canvas.ignoresSafeArea())
                .megrumHiddenNavigationBar()
        }
    }

    @ViewBuilder
    private var collectionTopChrome: some View {
        if showsHeader {
            CollectionHeader(
                title: title,
                subtitle: subtitle,
                columns: $columns,
                accessory: headerAccessory,
                showsColumnToggle: showsColumnToggle
            )
        }
        if entryKind == .inventory {
            InventoryStatusTabs(
                selectedStatus: $selectedInventoryStatus,
                counts: inventoryStatusCounts
            )
        }
    }

    private func collectionPageScroll(status: GoodsEntryStatus?, includesTopChrome: Bool = false) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                if includesTopChrome {
                    collectionTopChrome
                }
                if let appState {
                    CollectionFilterBar(
                        appState: appState,
                        selectedGroupID: $selectedGroupID,
                        selectedGoodsTypeID: $selectedGoodsTypeID,
                        selectedTagNames: $selectedTagNames,
                        availableGroups: availableGroups,
                        availableGoodsTypes: availableGoodsTypes,
                        availableTagNames: availableTagNames
                    )
                }
                GoodsCollectionResultsArea(
                    isShowingLoadingState: isShowingLoadingState,
                    filteredItems: filteredItems(for: status),
                    columns: columns,
                    emptyMessageTitle: emptyMessageTitle(for: status),
                    emptyMessageSystemImage: emptyMessageSystemImage(for: status),
                    emptyMessageDetail: emptyMessageDetail(for: status),
                    emptyMessageActionTitle: emptyMessageActionTitle,
                    emptyMessageAction: emptyMessageAction,
                    entryKind: entryKind,
                    viewerID: appState?.viewer?.id,
                    busyItemID: appState?.mutatingGoodsItemID,
                    isSelectionMode: isSelectionMode,
                    selectedItemIDs: selectedItemIDs,
                    onOpenItem: supportsOwnedItemQuickActions(for: status) ? { item in
                        if isSelectionMode {
                            toggleSelection(item)
                        } else if isOwnedItem(item) {
                            quickActionItem = item
                        }
                    } : nil,
                    onCreateIndividualListing: canCreateListingFromItems ? { listingSeedWish = $0 } : nil,
                    onEditItem: supportsSystemCardActions(for: status) ? { editorRoute = .edit($0, entryKind) } : nil,
                    onHideItem: supportsSystemCardActions(for: status) ? { hideItem($0) } : nil,
                    onDeleteItem: supportsSystemCardActions(for: status) ? { deleteItem($0) } : nil,
                    onBeginSelection: supportsInventoryManagementActions(for: status) ? { beginSelection(with: $0) } : nil,
                    onToggleSelection: supportsInventoryManagementActions(for: status) ? { toggleSelection($0) } : nil
                )
            }
            .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
            .padding(.top, includesTopChrome ? CollectionScreenLayoutMetrics.topPadding : 0)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
        }
    }

    private var addButtonLabel: String {
        entryKind == .inventory ? "マイグッズに追加" : "Wishに追加"
    }

    private var addButtonHint: String {
        entryKind == .inventory ? "新しいマイグッズの登録シートを開きます" : "新しいWishの登録シートを開きます"
    }

    private func loadFilterChoicesIfNeeded() async {
        guard let appState else {
            return
        }
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    private func hideItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.archiveGoodsItem(item.id)
        }
    }

    private func deleteItem(_ item: GoodsItem) {
        guard let appState else {
            return
        }
        Task {
            _ = await appState.deleteGoodsItem(item.id)
        }
    }

    private func beginSelection(with item: GoodsItem) {
        guard isOwnedItem(item) else {
            return
        }
        quickActionItem = nil
        selectedItemIDs = [item.id]
    }

    private func toggleSelection(_ item: GoodsItem) {
        guard isOwnedItem(item) else {
            return
        }
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func isOwnedItem(_ item: GoodsItem) -> Bool {
        guard let viewerID = appState?.viewer?.id else {
            return false
        }
        return item.ownerID == viewerID
    }

    private func performQuickAction(_ action: GoodsQuickActionKind) {
        guard let item = quickActionItem else {
            return
        }
        quickActionItem = nil

        switch action {
        case .edit:
            editorRoute = .edit(item, entryKind)
        case .moveToKeep:
            moveItem(item, to: item.status == .keep ? .active : .keep)
        case .tag:
            bulkTagRoute = GoodsBulkTagRoute(itemIDs: [item.id])
        case .delete:
            pendingSingleDeleteItem = item
        }
    }

    private func moveItem(_ item: GoodsItem, to status: GoodsEntryStatus) {
        guard let appState, let input = updateInput(for: item, status: status) else {
            editorRoute = .edit(item, entryKind)
            return
        }
        Task {
            _ = await appState.updateGoodsEntry(itemID: item.id, kind: entryKind, input: input)
        }
    }

    private func applyBulkTag(_ tagName: String, to itemIDs: Set<UUID>) {
        guard let appState else {
            return
        }
        let targetItems = items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
        Task {
            for item in targetItems {
                guard let input = updateInput(for: item, appendingTag: tagName) else {
                    continue
                }
                _ = await appState.updateGoodsEntry(itemID: item.id, kind: entryKind, input: input)
            }
            selectedItemIDs.subtract(itemIDs)
        }
    }

    private func bulkTagCandidateNames(for itemIDs: Set<UUID>) -> [String] {
        guard let appState else {
            return []
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let suggestions = groupIDs.flatMap { groupID in
            GoodsEditorTagSuggestionBuilder.suggestions(
                groupID: groupID,
                selectedTags: [],
                inventory: items,
                wishes: appState.wishes,
                limit: 10
            )
        }
        return TagNameNormalizer.uniquePreservingOrder(suggestions, limit: 10)
    }

    private func bulkTagPreviewItemsByTag(for itemIDs: Set<UUID>) -> [String: [TagPreviewItem]] {
        guard let appState else {
            return [:]
        }
        let groupIDs = orderedGroupIDs(from: bulkTagTargetItems(for: itemIDs))
        let selectedGroupID = groupIDs.count == 1 ? groupIDs.first : nil
        return IndividualListingConditionTagBuilder(
            inventory: items,
            wishes: appState.wishes,
            selectedGroupID: selectedGroupID
        )
        .previewItemsByTag()
    }

    private func bulkTagTargetItems(for itemIDs: Set<UUID>) -> [GoodsItem] {
        items.filter { itemIDs.contains($0.id) && isOwnedItem($0) }
    }

    private func orderedGroupIDs(from targetItems: [GoodsItem]) -> [UUID] {
        Array(Set(targetItems.compactMap(\.groupID)))
            .sorted { $0.uuidString < $1.uuidString }
    }

    private func deleteSelectedItems() {
        guard let appState else {
            return
        }
        let targetIDs = Set(selectedItems.filter(isOwnedItem).map(\.id))
        Task {
            for itemID in targetIDs {
                _ = await appState.deleteGoodsItem(itemID)
            }
            selectedItemIDs.subtract(targetIDs)
        }
    }

    private func updateInput(
        for item: GoodsItem,
        status: GoodsEntryStatus? = nil,
        appendingTag tagName: String? = nil
    ) -> GoodsEntryUpdateInput? {
        guard let groupID = item.groupID, let goodsTypeID = item.goodsTypeID else {
            return nil
        }
        var tagNames = item.tags.map(\.name)
        if let tagName, !tagNames.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
            tagNames.append(tagName)
        }
        return GoodsEntryUpdateInput(
            title: item.title,
            groupID: groupID,
            memberID: item.memberID,
            clearsMemberID: item.memberID == nil,
            goodsTypeID: goodsTypeID,
            quantity: item.quantity,
            status: status ?? item.status ?? .active,
            photoURLs: item.imageURL.map { [$0.absoluteString] },
            tagNames: tagNames
        )
    }

    private func resetFilters() {
        selectedGroupID = nil
        selectedGoodsTypeID = nil
        selectedTagNames = []
    }

    private func reconcileSelectedTags() {
        let available = Set(availableTagNames)
        selectedTagNames = selectedTagNames.intersection(available)
    }

    private func reconcileSelectedFilters() {
        if let selectedGroupID,
           appState?.isLoadingOshiGroups != true,
           !availableGroups.contains(where: { $0.id == selectedGroupID }) {
            self.selectedGroupID = nil
        }
        if let selectedGoodsTypeID,
           appState?.isLoadingGoodsTypes != true,
           !availableGoodsTypes.contains(where: { $0.id == selectedGoodsTypeID }) {
            self.selectedGoodsTypeID = nil
        }
        reconcileSelectedTags()
    }

    private var canCreateListingFromItems: Bool {
        appState != nil && entryKind == .wish
    }

    private func openAddForm() {
        if appState == nil {
            isShowingUnavailableAlert = true
        } else {
            editorRoute = .create(entryKind)
        }
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]
    var appState: MegrumAppState?
    @State private var selectedSection: WishSection = .wishes
    @State private var columns = GoodsGridLayout.minimumColumns

    private enum WishSection: String, CaseIterable, Identifiable {
        case wishes = "Wish"
        case listings = "個別募集"

        var id: String { rawValue }

        var navigationTitle: String {
            switch self {
            case .wishes:
                "ウィッシュ"
            case .listings:
                "個別募集"
            }
        }
    }

    private var goodsLikeItems: [GoodsItem] {
        items.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                kind: .wish,
                status: .active,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                imageURL: $0.imageURL,
                tags: $0.tags,
                quantity: $0.quantity
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
            CollectionHeader(
                title: selectedSection.navigationTitle,
                subtitle: "",
                columns: $columns,
                accessory: sectionPicker,
                showsColumnToggle: false
            )
            .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
            .padding(.top, CollectionScreenLayoutMetrics.topPadding)

            TabView(selection: $selectedSection) {
                ForEach(WishSection.allCases) { section in
                    wishSectionPage(section)
                        .tag(section)
                }
            }
            .megrumPageTabViewStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private func wishSectionPage(_ section: WishSection) -> some View {
        switch section {
        case .wishes:
            GoodsCollectionScreen(
                title: section.navigationTitle,
                subtitle: "",
                items: goodsLikeItems,
                showsAddButton: true,
                appState: appState,
                entryKind: .wish,
                showsHeader: false,
                showsColumnToggle: false
            )
        case .listings:
            if let appState {
                IndividualListingsScreen(
                    appState: appState,
                    headerTitle: section.navigationTitle,
                    showsHeader: false
                )
            } else {
                GoodsCollectionScreen(
                    title: section.navigationTitle,
                    subtitle: "条件を指定した募集",
                    items: [],
                    showsAddButton: false,
                    showsHeader: false,
                    showsColumnToggle: false
                )
            }
        }
    }

    private var sectionPicker: AnyView {
        AnyView(
            Picker("表示", selection: $selectedSection) {
                ForEach(WishSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Wishの表示切り替え")
            .frame(maxWidth: .infinity)
        )
    }
}
