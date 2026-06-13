import MegrumCore
import MegrumDesign
import SwiftUI

enum GoodsTileCollectionCardMetrics {
    static let imageHeightMultiplier: CGFloat = 1.34
    static let cornerRadius: CGFloat = 13
    static let gridSpacing: CGFloat = 10
    static let borderOpacity: CGFloat = 0.08
    static let shadowOpacity: CGFloat = 0.08
    static let shadowRadius: CGFloat = 9
    static let shadowX: CGFloat = 3
    static let shadowY: CGFloat = 6
    static let shineSize: CGFloat = 58
    static let shineCenterXOffset: CGFloat = 12
    static let shineCenterY: CGFloat = 17
    static let shineOpacity: CGFloat = 0.26
    static let glyphFontSize: CGFloat = 32
    static let tagInset: CGFloat = 6
    static let tagMaxWidthRatio: CGFloat = 0.78
    static let tagFontSize: CGFloat = 9
    static let tagHorizontalPadding: CGFloat = 6
    static let tagVerticalPadding: CGFloat = 3
}

enum GoodsTileCardPolicy {
    static func usesImageOnlyCard(for context: GoodsGridContext) -> Bool {
        context == .inventory || context == .wish
    }
}

enum GoodsSelectionFooterMetrics {
    static let bottomPadding: CGFloat = 12
    static let horizontalPadding: CGFloat = 18
    static let cornerRadius: CGFloat = 28
    static let actionHeight: CGFloat = 52
    static let actionSpacing: CGFloat = 10
}

enum GoodsQuickActionKind: CaseIterable, Identifiable, Equatable {
    case edit
    case moveToKeep
    case tag
    case delete

    static let inventoryActions: [GoodsQuickActionKind] = [.edit, .moveToKeep, .tag, .delete]

    var id: String { title }

    var title: String {
        switch self {
        case .edit:
            "編集する"
        case .moveToKeep:
            "自分用キープへ"
        case .tag:
            "タグをつける"
        case .delete:
            "削除する"
        }
    }

    var systemImage: String {
        switch self {
        case .edit:
            "square.and.pencil"
        case .moveToKeep:
            "archivebox"
        case .tag:
            "tag"
        case .delete:
            "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .edit, .moveToKeep, .tag:
            nil
        }
    }
}

enum GoodsTileCollectionCardStyle {
    static func tagLine(for item: GoodsItem) -> String {
        guard !item.tags.isEmpty else {
            return "タグ未設定"
        }

        let visibleTags = item.tags.prefix(2).map { "# \($0.name)" }.joined(separator: " ")
        return item.tags.count > 2 ? "\(visibleTags) ..." : visibleTags
    }

    static func glyph(for item: GoodsItem) -> String {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.contains("スア") {
            return "S"
        }
        if title.contains("ジョンウ") {
            return "J"
        }
        if title.contains("ニンニン") {
            return "N"
        }
        if title.contains("カリナ") {
            return "K"
        }
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch glyph(for: item) {
        case "S":
            Color(red: 0.796, green: 0.737, blue: 0.957)
        case "J":
            MegrumTheme.sky
        case "N":
            MegrumTheme.pink
        case "K":
            Color(red: 0.835, green: 0.812, blue: 0.957)
        default:
            switch abs(item.id.hashValue) % 4 {
            case 0:
                Color(red: 0.796, green: 0.737, blue: 0.957)
            case 1:
                MegrumTheme.sky
            case 2:
                MegrumTheme.pink
            default:
                Color(red: 0.835, green: 0.812, blue: 0.957)
            }
        }
    }
}

struct GoodsGridLayout: Equatable {
    static let minimumColumns = 3
    static let maximumColumns = 5
    static let columnSpacing: CGFloat = GoodsTileCollectionCardMetrics.gridSpacing
    static let rowSpacing: CGFloat = GoodsTileCollectionCardMetrics.gridSpacing
    static let tileAspectRatio: CGFloat = 1 / GoodsTileCollectionCardMetrics.imageHeightMultiplier
    static let tileCornerRadius: CGFloat = GoodsTileCollectionCardMetrics.cornerRadius

    var requestedColumns: Int

    init(columns: Int = Self.minimumColumns) {
        self.requestedColumns = columns
    }

    var columns: Int {
        min(Self.maximumColumns, max(Self.minimumColumns, requestedColumns))
    }

    var nextColumns: Int {
        columns >= Self.maximumColumns ? Self.minimumColumns : columns + 1
    }

    var skeletonTileCount: Int {
        columns * 2
    }
}

enum GoodsGridContext: Equatable {
    case inventory
    case wish
    case tradeCandidate

    init(entryKind: GoodsEntryKind) {
        switch entryKind {
        case .inventory:
            self = .inventory
        case .wish:
            self = .wish
        }
    }

    var statusLabel: String {
        switch self {
        case .inventory:
            "譲る候補"
        case .wish:
            "探し中"
        case .tradeCandidate:
            "交換候補"
        }
    }

    var quantityLabel: String {
        switch self {
        case .inventory:
            "マイグッズ数"
        case .wish:
            "希望数"
        case .tradeCandidate:
            "枚数"
        }
    }
}

struct GoodsTilePresentation: Equatable {
    var item: GoodsItem
    var context: GoodsGridContext
    var isBusy: Bool

    var statusLabel: String {
        if context == .inventory {
            return item.status?.inventoryTabTitle ?? GoodsEntryStatus.active.inventoryTabTitle
        }
        return context.statusLabel
    }

    var quantityText: String {
        "\(max(1, item.quantity))点"
    }

    var tagSummary: String? {
        guard !item.tags.isEmpty else {
            return nil
        }
        if item.tags.count == 1 {
            return "#\(item.tags[0].name)"
        }
        return "#\(item.tags[0].name) +\(item.tags.count - 1)"
    }

    var tileMetadataText: String {
        var parts = [statusLabel, quantityText]
        if let tagSummary {
            parts.append(tagSummary)
        }
        return parts.joined(separator: " ・ ")
    }

    var accessibilityValue: String {
        var values = [statusLabel, quantityText]
        if let tagSummary {
            values.append(tagSummary)
        }
        if isBusy {
            values.append("処理中")
        }
        return values.joined(separator: "、")
    }
}

struct GoodsTileActionPolicy: Equatable {
    var viewerID: UUID?
    var itemOwnerID: UUID
    var canAddToExchangeList: Bool
    var canCreateIndividualListing: Bool
    var canEdit: Bool
    var canHide: Bool
    var canDelete: Bool
    var canReport: Bool

    var actions: [GoodsTileAction] {
        guard let viewerID else {
            return [.detail]
        }

        if itemOwnerID == viewerID {
            var ownerActions: [GoodsTileAction] = [.detail]
            if canEdit {
                ownerActions.append(.edit)
            }
            if canCreateIndividualListing {
                ownerActions.append(.createIndividualListing)
            }
            if canHide {
                ownerActions.append(.hide)
            }
            if canDelete {
                ownerActions.append(.delete)
            }
            return ownerActions
        }

        var remoteActions: [GoodsTileAction] = [.detail]
        if canAddToExchangeList {
            remoteActions.append(.addToExchangeList)
        }
        if canReport {
            remoteActions.append(.report)
        }
        return remoteActions
    }
}

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
    @State private var pendingDeleteItem: GoodsItem?
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
                GoodsTile(
                    item: item,
                    context: context,
                    actions: actions(for: item),
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
                    usesSystemContextMenu: onBeginSelection == nil,
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
        .confirmationDialog("削除しますか？", isPresented: Binding(
            get: { pendingDeleteItem != nil },
            set: { if !$0 { pendingDeleteItem = nil } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let pendingDeleteItem {
                    onDeleteItem?(pendingDeleteItem)
                }
                pendingDeleteItem = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteItem = nil
            }
        } message: {
            if let pendingDeleteItem {
                Text("「\(pendingDeleteItem.title)」を削除します。")
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
                pendingDeleteItem = item
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

enum GoodsTileAction: CaseIterable, Identifiable, Equatable {
    case detail
    case addToExchangeList
    case createIndividualListing
    case edit
    case hide
    case report
    case delete

    static var visibleActions: [GoodsTileAction] {
        [.detail, .addToExchangeList, .edit, .hide, .report, .delete]
    }

    var id: String { title }

    var title: String {
        switch self {
        case .detail:
            "詳細を見る"
        case .addToExchangeList:
            "交換リストに追加"
        case .createIndividualListing:
            "これで個別募集する"
        case .edit:
            "編集"
        case .hide:
            "非表示にする"
        case .report:
            "通報する"
        case .delete:
            "削除する"
        }
    }

    var symbolName: String {
        switch self {
        case .detail:
            "info.circle"
        case .addToExchangeList:
            "plus.circle"
        case .createIndividualListing:
            "rectangle.stack.badge.plus"
        case .edit:
            "square.and.pencil"
        case .hide:
            "eye.slash"
        case .report:
            "exclamationmark.bubble"
        case .delete:
            "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .detail, .addToExchangeList, .createIndividualListing, .edit, .hide, .report:
            nil
        }
    }

    var isDestructive: Bool {
        role == .destructive
    }
}
