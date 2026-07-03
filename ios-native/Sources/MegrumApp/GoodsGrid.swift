import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsGrid: View {
    var items: [GoodsItem]
    var columns: Int = 3
    var context: GoodsGridContext = .tradeCandidate
    var viewerID: UUID?
    var onOpenItem: ((GoodsItem) -> Void)?
    var onOpenOwnerProfile: ((UUID) -> Void)?
    var onAddToExchangeList: ((GoodsItem) -> Void)?
    var onCreateIndividualListing: ((GoodsItem) -> Void)?
    var onEditItem: ((GoodsItem) -> Void)?
    var onHideItem: ((GoodsItem) -> Void)?
    var onDeleteItem: ((GoodsItem) -> Void)?
    var onReportItem: ((GoodsItem, GoodsReportReason, String) -> Void)?
    var busyItemID: UUID?
    var isSelectionMode = false
    var selectedItemIDs: Set<UUID> = []
    var onBeginSelection: ((GoodsItem) -> Void)?
    var onToggleSelection: ((GoodsItem) -> Void)?
    var animatesEntrance = false
    @State private var presentationState = GoodsGridPresentationState()
    @State private var entranceStartedAt = Date()

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GoodsGridLayout.columnSpacing), count: layout.columns)
    }

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: GoodsGridLayout.rowSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let tileActions = actions(for: item)
                GoodsTile(
                    item: item,
                    context: context,
                    actions: tileActions,
                    onOpenDetail: { handlePrimaryTap(item) },
                    onAction: { action in
                        handle(action, item: item)
                    },
                    isBusy: busyItemID == item.id,
                    isSelectionMode: isSelectionMode,
                    isSelected: selectedItemIDs.contains(item.id),
                    usesSystemContextMenu: GoodsTileContextMenuPolicy.isEnabled(
                        actions: tileActions,
                        hasLongPressSelection: onBeginSelection != nil
                    ),
                    onLongPress: onBeginSelection.map { beginSelection in
                        { beginSelection(item) }
                    }
                )
                .modifier(
                    GoodsGridEntranceEffect(
                        isEnabled: animatesEntrance,
                        row: index / layout.columns,
                        startedAt: entranceStartedAt
                    )
                )
            }
        }
        .modifier(
            GoodsGridPresentationModifier(
                presentationState: $presentationState,
                context: context,
                onReportItem: onReportItem
            )
        )
    }

    private func handlePrimaryTap(_ item: GoodsItem) {
        let policy = GoodsGridPrimaryTapPolicy(
            isSelectionMode: isSelectionMode,
            canToggleSelection: onToggleSelection != nil,
            canOpenItem: onOpenItem != nil,
            canOpenOwnerProfile: onOpenOwnerProfile != nil,
            viewerID: viewerID,
            itemOwnerID: item.ownerID
        )

        switch policy.destination {
        case .toggleSelection:
            onToggleSelection?(item)
        case .openItem:
            onOpenItem?(item)
        case .openOwnerProfile(let ownerID):
            onOpenOwnerProfile?(ownerID)
        case .showDetail:
            presentationState.showDetail(item)
        }
    }

    private func handle(_ action: GoodsTileAction, item: GoodsItem) {
        let policy = GoodsGridTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: item.ownerID,
            itemTitle: item.title,
            canAddToExchangeList: onAddToExchangeList != nil,
            canCreateIndividualListing: onCreateIndividualListing != nil,
            canEdit: onEditItem != nil,
            canHide: onHideItem != nil,
            canDelete: onDeleteItem != nil,
            canReport: onReportItem != nil
        )

        switch policy.destination(for: action) {
        case .showDetail:
            presentationState.showDetail(item)
        case .addToExchangeList:
            onAddToExchangeList?(item)
        case .createIndividualListing:
            onCreateIndividualListing?(item)
        case .edit:
            onEditItem?(item)
        case .hide:
            onHideItem?(item)
        case .showReport:
            presentationState.showReport(item)
        case .delete:
            onDeleteItem?(item)
        case .showActionMessage(let message):
            presentationState.showActionMessage(message)
        }
    }

    private func actions(for item: GoodsItem) -> [GoodsTileAction] {
        GoodsTileActionPolicy(
            viewerID: viewerID,
            itemOwnerID: item.ownerID,
            canAddToExchangeList: onAddToExchangeList != nil,
            canCreateIndividualListing: onCreateIndividualListing != nil,
            canEdit: onEditItem != nil,
            canHide: onHideItem != nil,
            canDelete: onDeleteItem != nil,
            canReport: onReportItem != nil
        )
        .actions
    }
}

/// Staggered row-by-row entrance for grid tiles: tiles drop in from above,
/// one row after another, when the grid first appears. Tiles appearing later
/// (scrolling) show instantly.
private struct GoodsGridEntranceEffect: ViewModifier {
    let isEnabled: Bool
    let row: Int
    let startedAt: Date

    @State private var isShown = false

    private static let entranceWindow: TimeInterval = 0.9
    private static let rowDelay: TimeInterval = 0.07
    private static let maxDelayedRows = 8

    func body(content: Content) -> some View {
        content
            .opacity(showsInPlace ? 1 : (isShown ? 1 : 0))
            .offset(y: showsInPlace ? 0 : (isShown ? 0 : -16))
            .onAppear {
                guard isEnabled, !isShown else {
                    return
                }
                if Date().timeIntervalSince(startedAt) > Self.entranceWindow {
                    isShown = true
                    return
                }
                let delay = Double(min(row, Self.maxDelayedRows)) * Self.rowDelay
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86).delay(delay)) {
                    isShown = true
                }
            }
    }

    private var showsInPlace: Bool {
        !isEnabled
    }
}
