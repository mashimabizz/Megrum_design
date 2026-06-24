import Foundation

extension IndividualListingDraft {
    static func boundedQuantity(_ quantity: Int, maxQuantity: Int = 99) -> Int {
        max(1, min(quantity, max(1, maxQuantity), 99))
    }

    static func defaultMinimumCount(for itemCount: Int, current: Int) -> Int {
        guard itemCount > 0 else {
            return 1
        }
        return boundedMinimumCount(current, itemCount: itemCount)
    }

    static func boundedMinimumCount(_ count: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else {
            return 1
        }
        return max(1, min(count, itemCount))
    }
}
