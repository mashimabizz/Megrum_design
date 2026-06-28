import MegrumCore
import MegrumDesign
import SwiftUI

extension GoodsCollectionScreen {
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
}
