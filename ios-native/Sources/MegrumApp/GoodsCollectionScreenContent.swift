import MegrumCore
import MegrumDesign
import SwiftUI

extension GoodsCollectionScreen {
    var activeFilter: GoodsCollectionFilter {
        GoodsCollectionFilter(groupID: selectedGroupID, goodsTypeID: selectedGoodsTypeID, tagNames: selectedTagNames)
    }

    func statusFilteredItems(for inventoryStatus: GoodsEntryStatus? = nil) -> [GoodsItem] {
        GoodsCollectionInventoryStatusPolicy.filteredItems(
            items,
            entryKind: entryKind,
            selectedStatus: selectedInventoryStatus,
            status: inventoryStatus
        )
    }

    var filteredItems: [GoodsItem] {
        filteredItems(for: nil)
    }

    func filteredItems(for inventoryStatus: GoodsEntryStatus?) -> [GoodsItem] {
        statusFilteredItems(for: inventoryStatus).filter(activeFilter.matches)
    }

    var hasActiveFilters: Bool {
        activeFilter.isActive
    }

    var isSelectionMode: Bool {
        !selectedItemIDs.isEmpty
    }

    var selectedItems: [GoodsItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func supportsOwnedBulkActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        GoodsCollectionBulkActionPolicy.allowsOwnedSelection(
            entryKind: entryKind,
            inventoryStatus: inventoryStatus ?? selectedInventoryStatus,
            hasAppState: appState != nil
        )
    }

    func supportsOwnedItemQuickActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        appState != nil && (entryKind == .wish || (entryKind == .inventory && !isReadOnlyInventoryPage(inventoryStatus)))
    }

    func supportsSystemCardActions(for inventoryStatus: GoodsEntryStatus?) -> Bool {
        appState != nil && entryKind == .inventory && !isReadOnlyInventoryPage(inventoryStatus)
    }

    func isReadOnlyInventoryPage(_ inventoryStatus: GoodsEntryStatus?) -> Bool {
        entryKind == .inventory && (inventoryStatus ?? selectedInventoryStatus) == .traded
    }

    var filterBaseItems: [GoodsItem] {
        statusFilteredItems()
    }

    var availableGroups: [OshiGroup] {
        guard let appState else {
            return []
        }
        return GoodsCollectionFilterChoices.groups(
            items: filterBaseItems,
            allGroups: appState.oshiGroups
        )
    }

    var availableGoodsTypes: [GoodsType] {
        guard let appState else {
            return []
        }
        return GoodsCollectionFilterChoices.goodsTypes(
            items: filterBaseItems,
            allGoodsTypes: appState.goodsTypes
        )
    }

    var availableTagNames: [String] {
        GoodsCollectionFilterChoices.tagNames(
            items: filterBaseItems,
            selectedGroupID: selectedGroupID,
            selectedGoodsTypeID: selectedGoodsTypeID
        )
    }

    var inventoryStatusCounts: [GoodsEntryStatus: Int] {
        GoodsCollectionInventoryStatusPolicy.counts(items: items)
    }

    var selectedInventoryStatusTitle: String {
        selectedInventoryStatus.inventoryTabTitle
    }

    var isShowingLoadingState: Bool {
        appState?.isLoading == true && items.isEmpty
    }

    func emptyMessageTitle(for inventoryStatus: GoodsEntryStatus?) -> String {
        emptyStatePresentation(for: inventoryStatus).title
    }

    func emptyMessageDetail(for inventoryStatus: GoodsEntryStatus?) -> String {
        emptyStatePresentation(for: inventoryStatus).detail
    }

    func emptyMessageSystemImage(for inventoryStatus: GoodsEntryStatus?) -> String {
        emptyStatePresentation(for: inventoryStatus).systemImage
    }

    func emptyStatePresentation(for inventoryStatus: GoodsEntryStatus?) -> GoodsCollectionEmptyStatePresentation {
        GoodsCollectionEmptyStatePresentation.make(
            hasActiveFilters: hasActiveFilters,
            screenTitle: title,
            entryKind: entryKind,
            inventoryStatus: inventoryStatus ?? selectedInventoryStatus
        )
    }

    var emptyMessageActionTitle: String? {
        if hasActiveFilters {
            return "フィルターをクリア"
        }
        return showsAddButton ? addButtonLabel : nil
    }

    var emptyMessageAction: (() -> Void)? {
        guard emptyMessageActionTitle != nil else {
            return nil
        }
        if hasActiveFilters {
            return { resetFilters() }
        }
        return { openAddForm() }
    }

    var hasPendingDeleteConfirmation: Bool {
        pendingSingleDeleteItem != nil || isConfirmingBulkDelete
    }

    var deleteConfirmationMessage: String {
        if let pendingSingleDeleteItem {
            return GoodsCollectionDeleteConfirmationPresentation.message(for: pendingSingleDeleteItem)
        }
        return GoodsCollectionDeleteConfirmationPresentation.message(selectedCount: selectedItemIDs.count)
    }

    var deleteConfirmationBottomPadding: CGFloat {
        isConfirmingBulkDelete ? 132 : FloatingActionLayoutMetrics.contentBottomPadding
    }

    var deleteConfirmationPopover: some View {
        AnchoredDestructiveConfirmationPopover(
            title: GoodsCollectionDeleteConfirmationPresentation.title,
            message: deleteConfirmationMessage,
            destructiveTitle: GoodsCollectionDeleteConfirmationPresentation.destructiveTitle,
            onCancel: dismissDeleteConfirmation,
            onConfirm: confirmPendingDelete,
            isConfirmEnabled: canConfirmDelete,
            showsArrow: false
        )
        .accessibilityHint("削除前の確認です")
    }

    @ViewBuilder
    var collectionContent: some View {
        if GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: entryKind, showsHeader: showsHeader) {
            VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                collectionTopChrome
                    .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
                    .padding(.top, CollectionScreenLayoutMetrics.topPadding)

                if entryKind == .inventory {
                    TabView(selection: $selectedInventoryStatus) {
                        ForEach(Self.inventoryStatuses, id: \.self) { status in
                            collectionPageScroll(status: status)
                                .tag(status)
                        }
                    }
                    .megrumPageTabViewStyle()
                } else {
                    collectionPageScroll(status: nil)
                }
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()
        } else {
            collectionPageScroll(status: nil)
                .background(MegrumTheme.canvas.ignoresSafeArea())
                .megrumHiddenNavigationBar()
        }
    }

    @ViewBuilder
    var collectionTopChrome: some View {
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

    func collectionPageScroll(status: GoodsEntryStatus?) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                if let appState {
                    CollectionFilterBar(
                        appState: appState,
                        selectedGroupID: $selectedGroupID,
                        selectedGoodsTypeID: $selectedGoodsTypeID,
                        selectedTagNames: $selectedTagNames,
                        items: filterBaseItems,
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
                            openQuickActionPanel(for: item)
                        }
                    } : nil,
                    onCreateIndividualListing: canCreateListingFromItems ? { listingSeedWish = $0 } : nil,
                    onEditItem: supportsSystemCardActions(for: status) ? { editorRoute = .edit($0, entryKind) } : nil,
                    onHideItem: supportsSystemCardActions(for: status) ? { hideItem($0) } : nil,
                    onDeleteItem: supportsSystemCardActions(for: status) ? { requestSingleDelete($0) } : nil,
                    onBeginSelection: supportsOwnedBulkActions(for: status) ? { beginSelection(with: $0) } : nil,
                    onToggleSelection: supportsOwnedBulkActions(for: status) ? { toggleSelection($0) } : nil,
                    adPlacement: adPlacement,
                    adDisplayContext: adDisplayContext
                )
            }
            .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
        }
    }

    var addButtonLabel: String {
        entryKind == .inventory ? "マイグッズに追加" : "Wishに追加"
    }

    var addButtonHint: String {
        entryKind == .inventory ? "新しいマイグッズの登録シートを開きます" : "新しいWishの登録シートを開きます"
    }

    var canCreateListingFromItems: Bool {
        appState != nil && entryKind == .wish
    }
}
