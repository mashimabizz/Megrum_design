import Foundation

enum HomeSeriesMatchPolicy {
    static let badgeTitle = "シリーズ○"

    static func normalizedSet(_ names: [String]) -> Set<String> {
        Set(names.compactMap { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
            let normalized = withoutHash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return normalized.nilIfBlank
        })
    }

    static func hasSeriesMatch(_ lhs: [String], _ rhs: [String]) -> Bool {
        let lhsSet = normalizedSet(lhs)
        guard !lhsSet.isEmpty else {
            return false
        }
        return !lhsSet.isDisjoint(with: normalizedSet(rhs))
    }

    static func matchedGoodsIDs(
        goods: [HomeMockGoods],
        offerGoods: [HomeMockGoods]
    ) -> Set<UUID> {
        let offerSeries = offerGoods.reduce(into: Set<String>()) { result, goods in
            result.formUnion(normalizedSet(goods.rawTagNames))
        }
        guard !offerSeries.isEmpty else {
            return []
        }
        return Set(goods.compactMap { goods in
            normalizedSet(goods.rawTagNames).isDisjoint(with: offerSeries) ? nil : goods.id
        })
    }

    static func orderedBySeriesMatch(
        _ goods: [HomeMockGoods],
        matchedIDs: Set<UUID>
    ) -> [HomeMockGoods] {
        guard !matchedIDs.isEmpty else {
            return goods
        }
        return goods.enumerated()
            .sorted { lhs, rhs in
                let lhsMatched = matchedIDs.contains(lhs.element.id)
                let rhsMatched = matchedIDs.contains(rhs.element.id)
                if lhsMatched != rhsMatched {
                    return lhsMatched && !rhsMatched
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
