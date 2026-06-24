import MegrumCore

enum HomeListingSelectionPolicy {
    static func initialWantedIndices(itemCount: Int, logic: ListingLogic) -> Set<Int> {
        switch logic {
        case .all:
            return allIndices(itemCount: itemCount)
        case .one:
            return []
        case .atLeast:
            return []
        }
    }

    static func wantedIndices(
        afterTapping index: Int,
        current: Set<Int>,
        itemCount: Int,
        logic: ListingLogic
    ) -> Set<Int> {
        guard (0..<itemCount).contains(index) else {
            return normalized(current, itemCount: itemCount)
        }

        switch logic {
        case .all:
            return allIndices(itemCount: itemCount)
        case .one:
            return current.contains(index) ? [] : [index]
        case .atLeast:
            var updated = normalized(current, itemCount: itemCount)
            if updated.contains(index) {
                updated.remove(index)
            } else {
                updated.insert(index)
            }
            return updated
        }
    }

    static func offerIndices(
        afterTapping index: Int,
        current: Set<Int>,
        itemCount: Int,
        logic: ListingLogic
    ) -> Set<Int> {
        guard (0..<itemCount).contains(index) else {
            return normalized(current, itemCount: itemCount)
        }

        switch logic {
        case .all:
            var updated = normalized(current, itemCount: itemCount)
            if updated.contains(index) {
                updated.remove(index)
            } else {
                updated.insert(index)
            }
            return updated
        case .one:
            return current.contains(index) ? [] : [index]
        case .atLeast:
            var updated = normalized(current, itemCount: itemCount)
            if updated.contains(index) {
                updated.remove(index)
            } else {
                updated.insert(index)
            }
            return updated
        }
    }

    static func label(for logic: ListingLogic) -> String {
        switch logic {
        case .all:
            return "すべて希望"
        case .one:
            return "どれか1つだけ"
        case .atLeast:
            return "何個以上"
        }
    }

    private static func allIndices(itemCount: Int) -> Set<Int> {
        guard itemCount > 0 else {
            return []
        }
        return Set(0..<itemCount)
    }

    private static func normalized(_ indices: Set<Int>, itemCount: Int) -> Set<Int> {
        guard itemCount > 0 else {
            return []
        }
        return indices.filter { (0..<itemCount).contains($0) }
    }
}
