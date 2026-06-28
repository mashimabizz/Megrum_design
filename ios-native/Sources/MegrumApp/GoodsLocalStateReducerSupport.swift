import Foundation
import MegrumCore

extension IndividualListing {
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

extension IndividualListingWishOption {
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

extension Array where Element == GoodsItem {
    mutating func replace(_ item: GoodsItem) {
        guard let index = firstIndex(where: { $0.id == item.id }) else {
            return
        }
        self[index] = item
    }
}

extension GoodsLocalState {
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

extension WishItem {
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
