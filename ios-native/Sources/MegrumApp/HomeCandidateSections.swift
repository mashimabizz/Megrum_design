import Foundation
import MegrumCore

public struct HomeCandidateSections: Equatable, Sendable {
    public var matchedItems: [GoodsItem]
    public var possibleItems: [GoodsItem]
    public var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    public var mutualMatchCandidates: [HomeMutualMatchCandidateData]

    public init(
        matchedItems: [GoodsItem] = [],
        possibleItems: [GoodsItem] = [],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:],
        mutualMatchCandidates: [HomeMutualMatchCandidateData] = []
    ) {
        self.matchedItems = matchedItems
        self.possibleItems = possibleItems
        self.conditionSignalsByItemID = conditionSignalsByItemID
        self.mutualMatchCandidates = mutualMatchCandidates
    }

    public var isEmpty: Bool {
        matchedItems.isEmpty && possibleItems.isEmpty && mutualMatchCandidates.isEmpty
    }

    func resolvedWithFallbackInventory(_ fallbackInventory: [GoodsItem]) -> HomeCandidateSections {
        guard isEmpty else {
            return self
        }

        let matchedItems = fallbackInventory
        let possibleItems = Array(fallbackInventory.reversed())
        return HomeCandidateSections(
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: HomeCandidateConditionSignalDefaults.previewSignals(
                matchedItems: matchedItems,
                possibleItems: possibleItems
            ),
            mutualMatchCandidates: mutualMatchCandidates
        )
    }
}
