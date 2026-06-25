import Foundation
import MegrumCore

extension IndividualListingDraft {
    mutating func setHaveQuantity(_ id: UUID, quantity: Int, maxQuantity: Int = 99) {
        guard selectedHaveIDs.contains(id) else {
            return
        }
        haveQuantities[id] = Self.boundedQuantity(quantity, maxQuantity: maxQuantity)
    }

    mutating func setWishQuantity(_ id: UUID, quantity: Int) {
        guard selectedWishIDs.contains(id) else {
            return
        }
        wishQuantities[id] = Self.boundedQuantity(quantity)
    }

    func haveQuantity(for id: UUID) -> Int {
        Self.boundedQuantity(haveQuantities[id] ?? 1)
    }

    func wishQuantity(for id: UUID) -> Int {
        Self.boundedQuantity(wishQuantities[id] ?? 1)
    }

    var resolvedHaveMinimumCount: Int {
        guard haveLogic == .atLeast else {
            return 1
        }
        return Self.boundedMinimumCount(haveMinimumCount, itemCount: selectedHaveIDs.count)
    }

    var resolvedWishMinimumCount: Int {
        guard wishLogic == .atLeast else {
            return 1
        }
        return Self.boundedMinimumCount(wishMinimumCount, itemCount: selectedWishIDs.count)
    }

    mutating func setHaveLogic(_ logic: ListingLogic) {
        haveLogic = logic
        if logic == .atLeast {
            haveMinimumCount = Self.defaultMinimumCount(for: selectedHaveIDs.count, current: haveMinimumCount)
        } else {
            haveMinimumCount = 1
        }
    }

    mutating func setWishLogic(_ logic: ListingLogic) {
        wishLogic = logic
        if logic == .atLeast {
            wishMinimumCount = Self.defaultMinimumCount(for: selectedWishIDs.count, current: wishMinimumCount)
        } else {
            wishMinimumCount = 1
        }
    }

    mutating func setHaveMinimumCount(_ count: Int) {
        haveMinimumCount = Self.boundedMinimumCount(count, itemCount: selectedHaveIDs.count)
        if selectedHaveIDs.count >= 2 {
            haveLogic = .atLeast
        }
    }

    mutating func setWishMinimumCount(_ count: Int) {
        wishMinimumCount = Self.boundedMinimumCount(count, itemCount: selectedWishIDs.count)
        if selectedWishIDs.count >= 2 {
            wishLogic = .atLeast
        }
    }
}
