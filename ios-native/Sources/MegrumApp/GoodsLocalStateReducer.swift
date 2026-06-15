import Foundation
import MegrumCore

public struct GoodsLocalState: Equatable, Sendable {
    public var inventory: [GoodsItem]
    public var wishes: [WishItem]
    public var homeMatchedItems: [GoodsItem]
    public var homePossibleItems: [GoodsItem]
    public var homeCandidateConditionSignals: [UUID: HomeCandidateConditionSignals]
    public var searchResults: [SearchResultItem]
    public var listings: [IndividualListing]

    public init(
        inventory: [GoodsItem],
        wishes: [WishItem],
        homeMatchedItems: [GoodsItem],
        homePossibleItems: [GoodsItem],
        homeCandidateConditionSignals: [UUID: HomeCandidateConditionSignals],
        searchResults: [SearchResultItem],
        listings: [IndividualListing]
    ) {
        self.inventory = inventory
        self.wishes = wishes
        self.homeMatchedItems = homeMatchedItems
        self.homePossibleItems = homePossibleItems
        self.homeCandidateConditionSignals = homeCandidateConditionSignals
        self.searchResults = searchResults
        self.listings = listings
    }
}

public enum GoodsLocalStateReducer {
    public static func removing(
        itemID: UUID,
        from state: GoodsLocalState
    ) -> GoodsLocalState {
        var next = state
        next.inventory.removeAll { $0.id == itemID }
        next.wishes.removeAll { $0.id == itemID }
        next.homeMatchedItems.removeAll { $0.id == itemID }
        next.homePossibleItems.removeAll { $0.id == itemID }
        next.homeCandidateConditionSignals.removeValue(forKey: itemID)
        next.searchResults.removeAll { $0.item.id == itemID }
        next.listings = state.listings.compactMap { listing in
            listing.removingGoodsItem(itemID)
        }
        return next
    }

    public static func upserting(
        _ item: GoodsItem,
        kind: GoodsEntryKind,
        in state: GoodsLocalState
    ) -> GoodsLocalState {
        var next = state
        next.inventory.removeAll { $0.id == item.id }
        next.wishes.removeAll { $0.id == item.id }

        switch kind {
        case .inventory:
            next.inventory.insert(item, at: 0)
        case .wish:
            next.wishes.insert(WishItem(goodsItem: item), at: 0)
        }

        next.homeMatchedItems.replace(item)
        next.homePossibleItems.replace(item)
        next.searchResults = next.searchResults.map { result in
            guard result.item.id == item.id else {
                return result
            }
            return SearchResultItem(
                item: item,
                ownerUserID: item.ownerID,
                bucket: searchBucket(for: item, wishes: next.wishes)
            )
        }
        return next
    }

    public static func searchBucket(
        for item: GoodsItem,
        wishes: [WishItem]
    ) -> SearchMatchBucket {
        let matchesWish = wishes.contains { wish in
            let groupMatches = wish.groupID == nil || item.groupID == wish.groupID
            let typeMatches = wish.goodsTypeID == nil || item.goodsTypeID == wish.goodsTypeID
            return groupMatches && typeMatches
        }
        return matchesWish ? .possible : .none
    }
}

private extension IndividualListing {
    func removingGoodsItem(_ itemID: UUID) -> IndividualListing? {
        var next = self
        next.haves.removeAll { $0.itemID == itemID }
        next.options = next.options.compactMap { option in
            option.removingGoodsItem(itemID)
        }
        return next.haves.isEmpty || next.options.isEmpty ? nil : next
    }
}

private extension IndividualListingWishOption {
    func removingGoodsItem(_ itemID: UUID) -> IndividualListingWishOption? {
        var next = self
        next.wishes.removeAll { $0.itemID == itemID }
        return next.wishes.isEmpty && !next.isCashOffer ? nil : next
    }
}

private extension Array where Element == GoodsItem {
    mutating func replace(_ item: GoodsItem) {
        guard let index = firstIndex(where: { $0.id == item.id }) else {
            return
        }
        self[index] = item
    }
}

private extension WishItem {
    init(goodsItem item: GoodsItem) {
        self.init(
            id: item.id,
            ownerID: item.ownerID,
            groupID: item.groupID,
            memberID: item.memberID,
            goodsTypeID: item.goodsTypeID,
            title: item.title,
            tags: item.tags
        )
    }
}
