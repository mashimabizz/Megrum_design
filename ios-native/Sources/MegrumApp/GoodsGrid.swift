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
    @State private var detailItem: GoodsItem?
    @State private var actionMessage: String?
    @State private var reportItem: GoodsItem?

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GoodsGridLayout.columnSpacing), count: layout.columns)
    }

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: GoodsGridLayout.rowSpacing) {
            ForEach(items) { item in
                let tileActions = actions(for: item)
                GoodsTile(
                    item: item,
                    context: context,
                    actions: tileActions,
                    onOpenDetail: {
                        if isSelectionMode, let onToggleSelection {
                            onToggleSelection(item)
                            return
                        }
                        if let onOpenItem {
                            onOpenItem(item)
                        } else if let onOpenOwnerProfile, item.ownerID != viewerID {
                            onOpenOwnerProfile(item.ownerID)
                        } else {
                            detailItem = item
                        }
                    },
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
            }
        }
        .sheet(item: $detailItem) { item in
            NavigationStack {
                GoodsDetailSheet(item: item, context: context)
            }
        }
        .sheet(item: $reportItem) { item in
            NavigationStack {
                GoodsReportSheet(item: item) { reason, note in
                    onReportItem?(item, reason, note)
                    reportItem = nil
                }
            }
        }
        .alert("まだ接続していません", isPresented: Binding(
            get: { actionMessage != nil },
            set: { if !$0 { actionMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let actionMessage {
                Text(actionMessage)
            }
        }
    }

    private func handle(_ action: GoodsTileAction, item: GoodsItem) {
        switch action {
        case .detail:
            detailItem = item
        case .addToExchangeList:
            if let onAddToExchangeList {
                onAddToExchangeList(item)
            } else {
                actionMessage = "「\(item.title)」を交換リストに追加する処理は、打診フローのSwift化で接続します。"
            }
        case .createIndividualListing:
            if let onCreateIndividualListing {
                onCreateIndividualListing(item)
            } else {
                actionMessage = "「\(item.title)」から個別募集を作成する処理は、Wish画面で使えます。"
            }
        case .edit:
            if item.ownerID == viewerID, let onEditItem {
                onEditItem(item)
            } else {
                actionMessage = "「\(item.title)」の編集は、自分のマイグッズ/Wishでのみ使えます。"
            }
        case .hide:
            if item.ownerID == viewerID, let onHideItem {
                onHideItem(item)
            } else {
                actionMessage = "「\(item.title)」を非表示にする処理は、自分のマイグッズ/Wishでのみ使えます。"
            }
        case .report:
            if item.ownerID != viewerID, onReportItem != nil {
                reportItem = item
            } else {
                actionMessage = "「\(item.title)」の通報導線は、他のユーザーのグッズでのみ使えます。"
            }
        case .delete:
            if item.ownerID == viewerID, onDeleteItem != nil {
                onDeleteItem?(item)
            } else {
                actionMessage = "「\(item.title)」を削除する処理は、自分のマイグッズ/Wishでのみ使えます。"
            }
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
