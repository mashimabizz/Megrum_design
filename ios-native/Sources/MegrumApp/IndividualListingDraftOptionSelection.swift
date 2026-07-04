extension IndividualListingDraft {
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
        // 定価・条件タブは「タブにいる＝選択中」とみなすため、追加後は
        // ほしいものタブへ戻して二重カウントを防ぐ。
        optionKind = .wish
    }
}
