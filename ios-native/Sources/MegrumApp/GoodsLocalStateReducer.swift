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

    public static func applyingCompletedTrade(
        proposal: TradeProposal,
        viewerID: UUID,
        viewerProfile: UserProfile?,
        knownGoodsByID: [UUID: GoodsItem],
        to state: GoodsLocalState
    ) -> GoodsLocalState {
        guard proposal.status == .completed,
              proposal.isParticipant(viewerID)
        else {
            return state
        }

        var next = state
        var historyItems: [GoodsItem] = []
        var keepItems: [GoodsItem] = []

        for (itemID, quantity) in quantityByItemID(proposal.goodsOffered(by: viewerID) ?? []) {
            guard let source = next.inventory.first(where: { $0.id == itemID }) ?? knownGoodsByID[itemID] else {
                continue
            }
            let transferQuantity = max(1, quantity)
            historyItems.append(
                transferredInventoryItem(
                    from: source,
                    ownerID: viewerID,
                    status: .traded,
                    quantity: transferQuantity,
                    viewerProfile: viewerProfile
                )
            )
            next = decrementingTradeableInventoryItem(
                itemID,
                quantity: transferQuantity,
                in: next
            )
        }

        for (itemID, quantity) in quantityByItemID(proposal.goodsRequested(by: viewerID) ?? []) {
            guard let source = knownGoodsByID[itemID] else {
                continue
            }
            keepItems.append(
                transferredInventoryItem(
                    from: source,
                    ownerID: viewerID,
                    status: .keep,
                    quantity: max(1, quantity),
                    viewerProfile: viewerProfile
                )
            )
        }

        next.inventory = keepItems + historyItems + next.inventory
        return next
    }

    private static func quantityByItemID(_ itemIDs: [UUID]) -> [(UUID, Int)] {
        var orderedIDs: [UUID] = []
        var quantities: [UUID: Int] = [:]
        for itemID in itemIDs {
            if quantities[itemID] == nil {
                orderedIDs.append(itemID)
            }
            quantities[itemID, default: 0] += 1
        }
        return orderedIDs.map { ($0, quantities[$0, default: 1]) }
    }

    private static func decrementingTradeableInventoryItem(
        _ itemID: UUID,
        quantity: Int,
        in state: GoodsLocalState
    ) -> GoodsLocalState {
        var next = state
        guard let itemIndex = next.inventory.firstIndex(where: { $0.id == itemID }) else {
            next.listings = next.listings.compactMap { $0.decrementingGoodsItem(itemID, quantity: quantity) }
            return next
        }

        let source = next.inventory[itemIndex]
        let remainingQuantity = max(0, source.quantity - quantity)
        if remainingQuantity > 0 {
            var updated = source
            updated.quantity = remainingQuantity
            updated.lockedQuantity = max(0, source.lockedQuantity - quantity)
            updated.marketAvailableQuantity = max(0, remainingQuantity - updated.lockedQuantity)
            next.inventory[itemIndex] = updated
            next.replaceReferencedGoodsItem(updated)
        } else {
            next.inventory.remove(at: itemIndex)
            next.removeReferencedGoodsItem(itemID)
        }

        next.listings = next.listings.compactMap { $0.decrementingGoodsItem(itemID, quantity: quantity) }
        return next
    }

    private static func transferredInventoryItem(
        from source: GoodsItem,
        ownerID: UUID,
        status: GoodsEntryStatus,
        quantity: Int,
        viewerProfile: UserProfile?
    ) -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: ownerID,
            kind: .inventory,
            status: status,
            groupID: source.groupID,
            memberID: source.memberID,
            goodsTypeID: source.goodsTypeID,
            groupName: source.groupName,
            memberName: source.memberName,
            goodsTypeName: source.goodsTypeName,
            title: source.title,
            imageURL: source.imageURL,
            tags: source.tags,
            quantity: max(1, quantity),
            lockedQuantity: 0,
            marketAvailableQuantity: 0,
            exchangeMethod: source.exchangeMethod,
            ownerPrefecture: viewerProfile?.prefecture,
            ownerDisplayName: viewerProfile?.displayName,
            ownerHandle: viewerProfile?.handle,
            ownerAvatarURL: viewerProfile?.avatarURL,
            ownerGender: viewerProfile?.gender,
            ownerAge: viewerProfile?.age,
            ownerPaymentMethods: viewerProfile?.paymentMethods ?? [],
            ownerPaymentNote: viewerProfile?.paymentNote
        )
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

    func decrementingGoodsItem(_ itemID: UUID, quantity: Int) -> IndividualListing? {
        var next = self
        next.haves = next.haves.compactMap { item in
            guard item.itemID == itemID else {
                return item
            }
            let remainingQuantity = item.quantity - quantity
            return remainingQuantity > 0
                ? ListingItemQuantity(itemID: item.itemID, quantity: remainingQuantity)
                : nil
        }
        next.options = next.options.compactMap { option in
            option.decrementingGoodsItem(itemID, quantity: quantity)
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

    func decrementingGoodsItem(_ itemID: UUID, quantity: Int) -> IndividualListingWishOption? {
        var next = self
        next.wishes = next.wishes.compactMap { item in
            guard item.itemID == itemID else {
                return item
            }
            let remainingQuantity = item.quantity - quantity
            return remainingQuantity > 0
                ? ListingItemQuantity(itemID: item.itemID, quantity: remainingQuantity)
                : nil
        }
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

private extension GoodsLocalState {
    mutating func replaceReferencedGoodsItem(_ item: GoodsItem) {
        homeMatchedItems.replace(item)
        homePossibleItems.replace(item)
        searchResults = searchResults.map { result in
            guard result.item.id == item.id else {
                return result
            }
            return SearchResultItem(item: item, ownerUserID: item.ownerID, bucket: result.bucket)
        }
    }

    mutating func removeReferencedGoodsItem(_ itemID: UUID) {
        homeMatchedItems.removeAll { $0.id == itemID }
        homePossibleItems.removeAll { $0.id == itemID }
        homeCandidateConditionSignals.removeValue(forKey: itemID)
        searchResults.removeAll { $0.item.id == itemID }
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
            imageURL: item.imageURL,
            tags: item.tags
        )
    }
}
