import Foundation

enum HomeExchangeCalendarDragSelectionPolicy {
    static func allowsSelection(
        startIndex: Int,
        endIndex: Int,
        translation: CGSize,
        columnCount: Int = 7
    ) -> Bool {
        guard columnCount > 0,
              abs(translation.width) > abs(translation.height) else {
            return false
        }
        return startIndex / columnCount == endIndex / columnCount
    }
}

enum HomeExchangeCalendarDragSelectionResolver {
    static func resolvedKeys(
        accumulatedKeys: Set<String>,
        finalKeys: [String],
        visibleKeys: [String]
    ) -> [String] {
        let selectedKeys = accumulatedKeys.union(finalKeys)
        guard !selectedKeys.isEmpty else {
            return []
        }
        return visibleKeys.filter { selectedKeys.contains($0) }
    }
}
