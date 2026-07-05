import MegrumCore
import MegrumDesign
import SwiftUI

extension GoodsCollectionScreen {
    @ViewBuilder
    var collectionContent: some View {
        if GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: entryKind, showsHeader: showsHeader) {
            Group {
                if entryKind == .inventory {
                    TabView(selection: $selectedInventoryStatus) {
                        ForEach(Self.inventoryStatuses, id: \.self) { status in
                            collectionPageScroll(status: status)
                                .tag(status)
                        }
                    }
                    .megrumPageTabViewStyle()
                    .megrumHiddenBottomScrollEdgeEffect()
                    .ignoresSafeArea(.container, edges: .bottom)
                } else {
                    collectionPageScroll(status: nil)
                }
            }
            .megrumPinnedTranslucentTopChrome(bottomEdge: expandedTopChromeBottomEdge) {
                VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                    collectionTopChrome
                }
                .padding(.horizontal, CollectionScreenLayoutMetrics.horizontalPadding)
                .padding(.top, CollectionScreenLayoutMetrics.topPadding)
                .padding(.bottom, 6)
            }
            .onChange(of: selectedInventoryStatus) { _, _ in
                resetTopChromeCollapse()
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
        if showsHeader && !isTopChromeCollapsed {
            CollectionHeader(
                title: title,
                subtitle: subtitle,
                columns: $columns,
                accessory: headerAccessory,
                showsColumnToggle: showsColumnToggle
            )
            .transition(MegrumTopChromeCollapseAnimation.titleTransition)
        }
        if entryKind == .inventory {
            InventoryStatusTabs(
                selectedStatus: $selectedInventoryStatus,
                counts: inventoryStatusCounts
            )
        }
    }

    /// While the chrome is collapsed, keep reporting the expanded height so
    /// scroll content does not jump when the title row hides.
    private var expandedTopChromeBottomEdge: Binding<CGFloat> {
        Binding(
            get: { topChromeHeight },
            set: { newValue in
                if !isTopChromeCollapsed {
                    topChromeHeight = newValue
                }
            }
        )
    }

    func handlePageScrollContentTop(_ contentTop: CGFloat, status: GoodsEntryStatus?) {
        if let status, entryKind == .inventory, status != selectedInventoryStatus {
            return
        }
        if let onScrollContentTopChange {
            onScrollContentTopChange(contentTop)
            return
        }
        guard GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: entryKind, showsHeader: showsHeader) else {
            return
        }
        let newValue = topChromeCollapseTracker.updatedCollapsedState(
            contentTop: contentTop,
            isCollapsed: isTopChromeCollapsed
        )
        guard newValue != isTopChromeCollapsed else {
            return
        }
        withAnimation(MegrumTopChromeCollapseAnimation.animation) {
            isTopChromeCollapsed = newValue
        }
    }

    func resetTopChromeCollapse() {
        topChromeCollapseTracker.reset()
        guard isTopChromeCollapsed else {
            return
        }
        withAnimation(MegrumTopChromeCollapseAnimation.animation) {
            isTopChromeCollapsed = false
        }
    }

    func collectionPageScroll(status: GoodsEntryStatus?) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.mainStackSpacing) {
                GoodsCollectionResultsArea(
                    isShowingLoadingState: isShowingLoadingState,
                    filteredItems: filteredItems(for: status),
                    columns: displayColumns,
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
            .padding(.top, pageTopContentInset)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
            .megrumReportsScrollContentTop()
            .megrumSuppressesEnclosingScrollEdgeEffects()
        }
        .coordinateSpace(name: MegrumScrollContentTopSpace.name)
        .onPreferenceChange(MegrumScrollContentTopPreferenceKey.self) { contentTop in
            MainActor.assumeIsolated {
                handlePageScrollContentTop(contentTop, status: status)
            }
        }
        .megrumHiddenBottomScrollEdgeEffect()
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// Inset that keeps scroll content starting below pinned translucent
    /// chrome: this screen's own chrome when it pins one, otherwise the value
    /// published by an enclosing screen (e.g. ほしいもの).
    var pageTopContentInset: CGFloat {
        max(
            pinnedTopChromeInset,
            GoodsCollectionChromePolicy.usesPinnedTopChrome(entryKind: entryKind, showsHeader: showsHeader)
                ? topChromeHeight + CollectionScreenLayoutMetrics.mainStackSpacing
                : 0
        )
    }
}
