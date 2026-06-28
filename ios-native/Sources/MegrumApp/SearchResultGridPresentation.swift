import MegrumCore
import SwiftUI

enum SearchResultGridEntry: Identifiable, Equatable {
    case goods(index: Int, SearchResultItem)
    case nativeAd(slotIndex: Int)

    var id: String {
        switch self {
        case let .goods(_, result):
            "goods-\(result.id.uuidString)"
        case let .nativeAd(slotIndex):
            "native-ad-\(slotIndex)"
        }
    }

    var goodsResult: SearchResultItem? {
        switch self {
        case let .goods(_, result):
            result
        case .nativeAd:
            nil
        }
    }
}

struct SearchResultGridRow: Identifiable, Equatable {
    var index: Int
    var cells: [SearchResultGridCell]

    var id: Int { index }
}

struct SearchResultGridCell: Identifiable, Equatable {
    var entry: SearchResultGridEntry
    var columnSpan: Int

    var id: String { entry.id }
}

enum SearchResultGridMetrics {
    static let columnCount = 3
    static let columnSpacing: CGFloat = 12
    static let rowSpacing: CGFloat = 14
    static let nativeAdColumnSpan = 2
    static let nativeAdCardHeight: CGFloat = 190
    static let nativeAdMediaHeight: CGFloat = 120
}

enum SearchResultGridLayout {
    static func rows(
        for entries: [SearchResultGridEntry],
        columnCount: Int = SearchResultGridMetrics.columnCount
    ) -> [SearchResultGridRow] {
        guard columnCount > 0 else {
            return []
        }

        var rows: [SearchResultGridRow] = []
        var currentCells: [SearchResultGridCell] = []
        var occupiedColumns = 0

        for entry in entries {
            let span = min(columnSpan(for: entry), columnCount)
            if occupiedColumns > 0, occupiedColumns + span > columnCount {
                rows.append(SearchResultGridRow(index: rows.count, cells: currentCells))
                currentCells = []
                occupiedColumns = 0
            }

            currentCells.append(SearchResultGridCell(entry: entry, columnSpan: span))
            occupiedColumns += span

            if occupiedColumns == columnCount {
                rows.append(SearchResultGridRow(index: rows.count, cells: currentCells))
                currentCells = []
                occupiedColumns = 0
            }
        }

        if !currentCells.isEmpty {
            rows.append(SearchResultGridRow(index: rows.count, cells: currentCells))
        }

        return rows
    }

    private static func columnSpan(for entry: SearchResultGridEntry) -> Int {
        switch entry {
        case .goods:
            1
        case .nativeAd:
            SearchResultGridMetrics.nativeAdColumnSpan
        }
    }
}

enum SearchResultAdInsertion {
    static let organicInterval = 4

    static func entries(
        for results: [SearchResultItem],
        includesNativeAds: Bool,
        organicInterval: Int = organicInterval
    ) -> [SearchResultGridEntry] {
        guard includesNativeAds, organicInterval > 0 else {
            return results.enumerated().map { index, result in
                .goods(index: index, result)
            }
        }

        var entries: [SearchResultGridEntry] = []
        var insertedAdCount = 0

        for (index, result) in results.enumerated() {
            entries.append(.goods(index: index, result))
            let organicCount = index + 1
            if organicCount.isMultiple(of: organicInterval), organicCount < results.count {
                insertedAdCount += 1
                entries.append(.nativeAd(slotIndex: insertedAdCount))
            }
        }

        return entries
    }
}

enum SearchResultHomePresentation {
    static func signals(
        for result: SearchResultItem,
        index: Int,
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> HomeCandidateConditionSignals {
        explicitSignals[result.item.id] ?? fallbackSignals(for: result.bucket, index: index)
    }

    static func sheet(
        for result: SearchResultItem,
        index: Int,
        goodsTypes: [GoodsType],
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> HomeDiscoverySheet {
        let signals = signals(for: result, index: index, explicitSignals: explicitSignals)
        let payload = HomeDiscoverySheetPayload(
            goods: HomeMockGoods.from(item: result.item, index: index, goodsTypes: goodsTypes),
            signals: signals
        )
        switch HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) {
        case .direct:
            return .goodsHit(payload)
        case .wish, .none:
            return .wishHit(payload)
        }
    }

    private static func fallbackSignals(for bucket: SearchMatchBucket, index: Int) -> HomeCandidateConditionSignals {
        switch bucket {
        case .matched:
            HomeCandidateConditionSignalDefaults.matched(index: index)
        case .possible:
            HomeCandidateConditionSignalDefaults.possible(index: index)
        case .none:
            HomeCandidateConditionSignalDefaults.noEvidence
        }
    }
}
