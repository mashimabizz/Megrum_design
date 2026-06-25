import Foundation
import MegrumCore

extension IndividualListingDraft {
    mutating func toggleHave(_ id: UUID, maxQuantity: Int = 99) {
        let previousCount = selectedHaveIDs.count
        haveOfferKind = .goods
        if selectedHaveIDs.contains(id) {
            selectedHaveIDs.remove(id)
            haveQuantities.removeValue(forKey: id)
        } else {
            selectedHaveIDs.insert(id)
            haveQuantities[id] = Self.boundedQuantity(haveQuantities[id] ?? 1, maxQuantity: maxQuantity)
        }
        normalizeHaveMinimumCount()
        defaultHaveMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func selectAllHaves(_ items: [GoodsItem]) {
        guard !items.isEmpty else {
            return
        }
        let previousCount = selectedHaveIDs.count
        haveOfferKind = .goods
        for item in items {
            selectedHaveIDs.insert(item.id)
            haveQuantities[item.id] = Self.boundedQuantity(
                haveQuantities[item.id] ?? 1,
                maxQuantity: maxHaveQuantity(for: item)
            )
        }
        normalizeHaveMinimumCount()
        defaultHaveMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func deselectHaves(_ items: [GoodsItem]) {
        guard !items.isEmpty else {
            return
        }
        for item in items {
            selectedHaveIDs.remove(item.id)
            haveQuantities.removeValue(forKey: item.id)
        }
        normalizeHaveMinimumCount()
    }

    mutating func toggleWish(_ id: UUID) {
        let previousCount = selectedWishIDs.count
        if selectedWishIDs.contains(id) {
            selectedWishIDs.remove(id)
            wishQuantities.removeValue(forKey: id)
        } else {
            selectedWishIDs.insert(id)
            wishQuantities[id] = Self.boundedQuantity(wishQuantities[id] ?? 1)
        }
        normalizeWishMinimumCount()
        defaultWishMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func selectAllWishes(_ items: [WishItem]) {
        guard !items.isEmpty else {
            return
        }
        let previousCount = selectedWishIDs.count
        for item in items {
            selectedWishIDs.insert(item.id)
            wishQuantities[item.id] = Self.boundedQuantity(wishQuantities[item.id] ?? 1)
        }
        normalizeWishMinimumCount()
        defaultWishMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func deselectWishes(_ items: [WishItem]) {
        guard !items.isEmpty else {
            return
        }
        for item in items {
            selectedWishIDs.remove(item.id)
            wishQuantities.removeValue(forKey: item.id)
        }
        normalizeWishMinimumCount()
    }

}

private extension IndividualListingDraft {
    mutating func normalizeHaveMinimumCount() {
        guard haveLogic == .atLeast else {
            haveMinimumCount = 1
            return
        }
        if selectedHaveIDs.count < 2 {
            haveLogic = .all
            haveMinimumCount = 1
        } else {
            haveMinimumCount = Self.boundedMinimumCount(haveMinimumCount, itemCount: selectedHaveIDs.count)
        }
    }

    mutating func normalizeWishMinimumCount() {
        guard wishLogic == .atLeast else {
            wishMinimumCount = 1
            return
        }
        if selectedWishIDs.count < 2 {
            wishLogic = .one
            wishMinimumCount = 1
        } else {
            wishMinimumCount = Self.boundedMinimumCount(wishMinimumCount, itemCount: selectedWishIDs.count)
        }
    }

    mutating func defaultHaveMinimumLogicIfNeeded(previousCount: Int) {
        guard previousCount < 2, selectedHaveIDs.count >= 2 else {
            return
        }
        haveLogic = .atLeast
        haveMinimumCount = 1
    }

    mutating func defaultWishMinimumLogicIfNeeded(previousCount: Int) {
        guard previousCount < 2, selectedWishIDs.count >= 2 else {
            return
        }
        wishLogic = .atLeast
        wishMinimumCount = 1
    }
}
