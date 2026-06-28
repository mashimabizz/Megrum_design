import Foundation
import MegrumCore

enum BlockedUserContentFilter {
    static func goods(_ items: [GoodsItem], blockedUserIDs: Set<UUID>) -> [GoodsItem] {
        guard !blockedUserIDs.isEmpty else {
            return items
        }
        return items.filter { !blockedUserIDs.contains($0.ownerID) }
    }

    static func searchResults(_ results: [SearchResultItem], blockedUserIDs: Set<UUID>) -> [SearchResultItem] {
        guard !blockedUserIDs.isEmpty else {
            return results
        }
        return results.filter { !blockedUserIDs.contains($0.ownerUserID) }
    }

    static func listings(_ listings: [IndividualListing], blockedUserIDs: Set<UUID>) -> [IndividualListing] {
        guard !blockedUserIDs.isEmpty else {
            return listings
        }
        return listings.filter { !blockedUserIDs.contains($0.ownerID) }
    }

    static func homeSections(
        _ sections: HomeCandidateSections,
        blockedUserIDs: Set<UUID>
    ) -> HomeCandidateSections {
        guard !blockedUserIDs.isEmpty else {
            return sections
        }
        let matchedItems = goods(sections.matchedItems, blockedUserIDs: blockedUserIDs)
        let possibleItems = goods(sections.possibleItems, blockedUserIDs: blockedUserIDs)
        let visibleItemIDs = Set((matchedItems + possibleItems).map(\.id))
        return HomeCandidateSections(
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: sections.conditionSignalsByItemID.filter { visibleItemIDs.contains($0.key) },
            mutualMatchCandidates: mutualMatchCandidates(
                sections.mutualMatchCandidates,
                blockedUserIDs: blockedUserIDs
            )
        )
    }

    static func mutualMatchCandidates(
        _ candidates: [HomeMutualMatchCandidateData],
        blockedUserIDs: Set<UUID>
    ) -> [HomeMutualMatchCandidateData] {
        guard !blockedUserIDs.isEmpty else {
            return candidates
        }
        return candidates.filter { candidate in
            if let partnerID = candidate.partnerID, blockedUserIDs.contains(partnerID) {
                return false
            }
            return !candidate.partnerGoodsItems.contains { blockedUserIDs.contains($0.ownerID) }
        }
    }
}
