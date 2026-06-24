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

    mutating func setOptionKind(_ kind: IndividualListingOptionKind) {
        optionKind = kind
        if kind != .wish, wishLogic == .atLeast {
            wishLogic = .one
            wishMinimumCount = 1
        }
    }

    mutating func setHaveOfferKind(_ kind: IndividualListingHaveOfferKind) {
        haveOfferKind = kind
        if kind == .cash {
            selectedHaveIDs.removeAll()
            haveQuantities.removeAll()
            haveLogic = .all
            haveMinimumCount = 1
        }
    }

    mutating func ensureDefaultCondition(groupID: UUID?, goodsTypeID: UUID?) {
        if conditionGroupID == nil {
            conditionGroupID = groupID
        }
        if conditionGoodsTypeID == nil {
            conditionGoodsTypeID = goodsTypeID
        }
    }

    mutating func setConditionGroupID(_ id: UUID?) {
        guard conditionGroupID != id else {
            return
        }
        conditionGroupID = id
        conditionMemberIDs.removeAll()
        excludesSelectedConditionMembers = false
        conditionTagNames.removeAll()
    }

    mutating func toggleConditionMember(_ id: UUID) {
        if conditionMemberIDs.contains(id) {
            conditionMemberIDs.remove(id)
            if conditionMemberIDs.isEmpty {
                excludesSelectedConditionMembers = false
            }
        } else {
            conditionMemberIDs.insert(id)
        }
    }

    mutating func setExcludesSelectedConditionMembers(_ value: Bool) {
        excludesSelectedConditionMembers = value && !conditionMemberIDs.isEmpty
    }

    mutating func toggleConditionTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        if let index = conditionTagNames.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            conditionTagNames.remove(at: index)
        } else if conditionTagNames.count < 5 {
            conditionTagNames.append(trimmed)
        }
    }

    mutating func setConditionQuantity(_ quantity: Int) {
        conditionQuantity = Self.boundedQuantity(quantity)
    }

    mutating func resetCurrentOptionSelection() {
        switch optionKind {
        case .wish:
            selectedWishIDs.removeAll()
            wishQuantities.removeAll()
            wishLogic = .one
            wishMinimumCount = 1
        case .condition:
            conditionGroupID = nil
            conditionMemberIDs.removeAll()
            excludesSelectedConditionMembers = false
            conditionGoodsTypeID = nil
            conditionTagNames.removeAll()
            conditionQuantity = 1
            if wishLogic == .atLeast {
                wishLogic = .one
                wishMinimumCount = 1
            }
        case .cash:
            cashPricingMode = .listPrice
            cashAmount = 1_100
            if wishLogic == .atLeast {
                wishLogic = .one
                wishMinimumCount = 1
            }
        }
    }

    var usesConditionLogicChoice: Bool {
        conditionMemberIDs.count > 1 || excludesSelectedConditionMembers
    }

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
