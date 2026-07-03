struct HomeExchangeCalendarDragPreviewState: Equatable {
    var dragPreviewKeys: Set<String> = []

    func activeSelectedDateKeys(selectedDateKeys: Set<String>) -> Set<String> {
        selectedDateKeys.union(dragPreviewKeys)
    }

    mutating func updatePreview(
        finalDays: [HomeExchangeCalendarDay],
        visibleDays: [HomeExchangeCalendarDay]
    ) {
        let resolvedKeys = Self.resolvedKeys(
            accumulatedKeys: dragPreviewKeys,
            finalDays: finalDays,
            visibleDays: visibleDays
        )
        let nextPreviewKeys = Set(resolvedKeys)
        guard !nextPreviewKeys.isEmpty,
              nextPreviewKeys != dragPreviewKeys else {
            return
        }
        dragPreviewKeys = nextPreviewKeys
    }

    mutating func finishDragSelection(
        finalDays: [HomeExchangeCalendarDay],
        visibleDays: [HomeExchangeCalendarDay]
    ) -> [HomeExchangeCalendarDay] {
        let resolvedKeys = Self.resolvedKeys(
            accumulatedKeys: dragPreviewKeys,
            finalDays: finalDays,
            visibleDays: visibleDays
        )
        let dayByKey = Dictionary(uniqueKeysWithValues: visibleDays.map { ($0.key, $0) })
        dragPreviewKeys = []
        return resolvedKeys.compactMap { dayByKey[$0] }
    }

    private static func resolvedKeys(
        accumulatedKeys: Set<String>,
        finalDays: [HomeExchangeCalendarDay],
        visibleDays: [HomeExchangeCalendarDay]
    ) -> [String] {
        HomeExchangeCalendarDragSelectionResolver.resolvedKeys(
            accumulatedKeys: accumulatedKeys,
            finalKeys: finalDays.map(\.key),
            visibleKeys: visibleDays.map(\.key)
        )
    }
}
