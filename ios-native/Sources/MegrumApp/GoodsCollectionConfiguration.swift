import MegrumCore
import SwiftUI

struct GoodsCollectionFilter: Equatable {
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var tagNames: Set<String> = []

    var isActive: Bool {
        groupID != nil || memberID != nil || goodsTypeID != nil || !tagNames.isEmpty
    }

    var activeCount: Int {
        var count = 0
        if groupID != nil { count += 1 }
        if memberID != nil { count += 1 }
        if goodsTypeID != nil { count += 1 }
        count += tagNames.count
        return count
    }

    func matches(_ item: GoodsItem) -> Bool {
        if let groupID, item.groupID != groupID {
            return false
        }
        if let memberID, item.memberID != memberID {
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
    /// Initial estimate of the pinned chrome's bottom edge (status bar +
    /// title + tabs) so the first layout pass starts content at roughly the
    /// right offset instead of visibly dropping down once the real
    /// measurement arrives.
    static let estimatedPinnedChromeBottomEdge: CGFloat = 186
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

enum GoodsCollectionChromePolicy {
    static func usesPinnedTopChrome(entryKind: GoodsEntryKind, showsHeader: Bool) -> Bool {
        showsHeader || entryKind == .inventory
    }
}

enum GoodsCollectionBulkActionPolicy {
    static func allowsOwnedSelection(
        entryKind: GoodsEntryKind,
        inventoryStatus: GoodsEntryStatus?,
        hasAppState: Bool
    ) -> Bool {
        guard hasAppState else {
            return false
        }

        switch entryKind {
        case .inventory:
            return inventoryStatus != .traded
        case .wish:
            return true
        }
    }
}

enum GoodsCollectionInventoryStatusPolicy {
    static let displayedStatuses: [GoodsEntryStatus] = [.active, .keep, .traded]

    static func filteredItems(
        _ items: [GoodsItem],
        entryKind: GoodsEntryKind,
        selectedStatus: GoodsEntryStatus,
        status: GoodsEntryStatus?
    ) -> [GoodsItem] {
        guard entryKind == .inventory else {
            return items
        }
        let resolvedStatus = status ?? selectedStatus
        return items.filter { item in
            matches(item, status: resolvedStatus)
        }
    }

    static func counts(items: [GoodsItem]) -> [GoodsEntryStatus: Int] {
        Dictionary(uniqueKeysWithValues: displayedStatuses.map { status in
            (status, items.filter { matches($0, status: status) }.count)
        })
    }

    private static func matches(_ item: GoodsItem, status: GoodsEntryStatus) -> Bool {
        switch status {
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

struct GoodsCollectionEmptyStatePresentation {
    var title: String
    var detail: String
    var systemImage: String

    static func make(
        hasActiveFilters: Bool,
        screenTitle: String,
        entryKind: GoodsEntryKind,
        inventoryStatus: GoodsEntryStatus
    ) -> GoodsCollectionEmptyStatePresentation {
        if hasActiveFilters {
            return GoodsCollectionEmptyStatePresentation(
                title: "条件に合うグッズがありません",
                detail: "フィルターを変えると表示されることがあります。",
                systemImage: "line.3.horizontal.decrease.circle"
            )
        }
        if screenTitle == "個別募集" {
            return GoodsCollectionEmptyStatePresentation(
                title: "個別募集はまだありません",
                detail: "条件を指定した募集は、ほしいものから作成できます。",
                systemImage: "rectangle.stack.badge.plus"
            )
        }

        switch entryKind {
        case .inventory:
            return inventoryPresentation(for: inventoryStatus)
        case .wish:
            return GoodsCollectionEmptyStatePresentation(
                title: "ほしいものはまだありません",
                detail: "探したいグッズを登録すると、候補探しに使えるようになります。",
                systemImage: "heart"
            )
        }
    }

    private static func inventoryPresentation(for status: GoodsEntryStatus) -> GoodsCollectionEmptyStatePresentation {
        switch status {
        case .active, .reserved:
            return GoodsCollectionEmptyStatePresentation(
                title: "譲る候補はまだありません",
                detail: "譲る候補を登録すると、検索や打診に使えるようになります。",
                systemImage: "shippingbox"
            )
        case .keep:
            return GoodsCollectionEmptyStatePresentation(
                title: "自分用キープはまだありません",
                detail: "交換に出さない手元用グッズはここで管理できます。",
                systemImage: "archivebox"
            )
        case .traded:
            return GoodsCollectionEmptyStatePresentation(
                title: "過去に譲ったグッズはまだありません",
                detail: "譲渡済みのグッズはここにまとまります。",
                systemImage: "checkmark.seal"
            )
        case .archived:
            return GoodsCollectionEmptyStatePresentation(
                title: "非表示のグッズはありません",
                detail: "非表示にしたグッズは通常の一覧から外れます。",
                systemImage: "eye.slash"
            )
        }
    }
}

enum WishCollectionPresentationPolicy {
    static let usesDirectSectionRendering = false
    static let usesSwipePaging = true
}
