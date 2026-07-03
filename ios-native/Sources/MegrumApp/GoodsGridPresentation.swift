import Foundation
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
    /// Measured from the screen bottom (the containers ignore the bottom safe
    /// area): clears the floating tab bar (~83pt) so the footer sits above it.
    static let bottomPadding: CGFloat = 106
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
    static let wishActions: [GoodsQuickActionKind] = [.edit, .tag, .delete]

    static func actions(for entryKind: GoodsEntryKind) -> [GoodsQuickActionKind] {
        switch entryKind {
        case .inventory:
            inventoryActions
        case .wish:
            wishActions
        }
    }

    var id: String { title }

    var title: String {
        title(for: nil)
    }

    func title(for itemStatus: GoodsEntryStatus?) -> String {
        switch self {
        case .edit:
            "編集する"
        case .moveToKeep:
            itemStatus == .keep ? "譲る候補へ" : "自分用キープへ"
        case .tag:
            "シリーズを設定"
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
        tagLine(for: item.tags)
    }

    static func tagLine(for tags: [GoodsTag]) -> String {
        guard !tags.isEmpty else {
            return "シリーズ未設定"
        }

        let visibleTags = tags.prefix(2).map { "# \($0.name)" }.joined(separator: " ")
        return tags.count > 2 ? "\(visibleTags) ..." : visibleTags
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
