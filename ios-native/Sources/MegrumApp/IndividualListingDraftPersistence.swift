import Foundation
import MegrumCore

extension IndividualListingDraft {
    func validationMessage(inventory: [GoodsItem], wishes: [WishItem]) -> String? {
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        switch haveOfferKind {
        case .goods:
            if selectedHaveIDs.isEmpty {
                return "譲るものを選択してください"
            }
            if selectedHaveItems.count != selectedHaveIDs.count {
                return "選択したマイグッズを読み込めませんでした"
            }
            if selectedHaveItems.contains(where: { maxHaveQuantity(for: $0) <= 0 }) {
                return "選択した譲るものの残数が足りません"
            }
            if selectedHaveItems.contains(where: { haveQuantity(for: $0.id) > maxHaveQuantity(for: $0) }) {
                return "選択した譲るものの残数が足りません"
            }
            if !hasSameGroupAndType(selectedHaveItems) {
                return "譲るものは同じグループ・同じ種別で選んでください"
            }
            if haveLogic == .atLeast, selectedHaveIDs.count < 2 {
                return "「何個以上」は2件以上選んだ時に設定できます"
            }
        case .cash:
            if haveCashPricingMode == .specifiedAmount, haveCashAmount <= 0 {
                return "金額を入力してください"
            }
        }

        switch optionKind {
        case .wish:
            if selectedWishIDs.isEmpty {
                return "求めるものを選択してください"
            }
            let selectedWishItems = selectedWishItems(from: wishes)
            if selectedWishItems.count != selectedWishIDs.count {
                return "選択したWishを読み込めませんでした"
            }
            if !hasSameGroupAndType(selectedWishItems) {
                return "求めるものは同じグループ・同じ種別で選んでください"
            }
            if wishLogic == .atLeast, selectedWishIDs.count < 2 {
                return "「何個以上」は2件以上選んだ時に設定できます"
            }
            if haveLogic == .one, wishLogic == .one, selectedHaveIDs.count > 1, selectedWishIDs.count > 1 {
                return "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
            }
        case .condition:
            if conditionGroupID == nil || conditionGoodsTypeID == nil {
                return "グループとグッズ種別を選択してください"
            }
        case .cash:
            if cashPricingMode == .specifiedAmount, cashAmount <= 0 {
                return "金額を入力してください"
            }
        }
        return nil
    }

    func createInput(inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListingCreateInput? {
        guard validationMessage(inventory: inventory, wishes: wishes) == nil else {
            return nil
        }
        let selectedWishItems = optionKind == .wish ? selectedWishItems(from: wishes) : []
        return IndividualListingCreateInput(
            haveItems: haveOfferKind == .cash ? [] : selectedInventoryItems(from: inventory).map { item in
                ListingItemQuantity(
                    itemID: item.id,
                    quantity: min(haveQuantity(for: item.id), max(1, maxHaveQuantity(for: item)))
                )
            },
            haveLogic: haveLogic,
            haveMinimumCount: haveLogic == .atLeast ? resolvedHaveMinimumCount : 1,
            wishItems: selectedWishItems.map { item in
                ListingItemQuantity(itemID: item.id, quantity: wishQuantity(for: item.id))
            },
            wishLogic: wishLogic,
            wishMinimumCount: wishLogic == .atLeast ? resolvedWishMinimumCount : 1,
            exchangeType: exchangeType,
            isCashOffer: optionKind == .cash,
            cashAmount: optionKind == .cash && cashPricingMode == .specifiedAmount ? cashAmount : nil,
            wishGroupID: optionWishGroupID(selectedWishItems: selectedWishItems),
            wishGoodsTypeID: optionWishGoodsTypeID(selectedWishItems: selectedWishItems),
            note: trimmedNoteWithListingMetadata
        )
    }

    func updatedListing(from original: IndividualListing, inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListing? {
        guard let input = createInput(inventory: inventory, wishes: wishes) else {
            return nil
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        var options = original.options.sorted { $0.position < $1.position }
        let existingOption = options.first
        let updatedOption = IndividualListingWishOption(
            id: existingOption?.id ?? UUID(),
            listingID: original.id,
            position: existingOption?.position ?? 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            minimumCount: input.wishMinimumCount,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            createdAt: existingOption?.createdAt,
            updatedAt: Date()
        )
        if options.isEmpty {
            options = [updatedOption]
        } else {
            options[0] = updatedOption
        }
        return IndividualListing(
            id: original.id,
            ownerID: original.ownerID,
            haves: input.haveItems,
            haveLogic: input.haveLogic,
            haveMinimumCount: input.haveMinimumCount,
            haveGroupID: haveOfferKind == .cash ? nil : selectedHaveItems.first?.groupID,
            haveGoodsTypeID: haveOfferKind == .cash ? nil : selectedHaveItems.first?.goodsTypeID,
            status: status,
            note: input.note,
            options: options,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
    }

    func maxHaveQuantity(for item: GoodsItem) -> Int {
        max(0, item.marketAvailableQuantity) + originalHaveQuantity(for: item.id)
    }
}

private extension IndividualListingDraft {
    var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedNoteWithListingMetadata: String? {
        var lines: [String] = []
        if let trimmedNote {
            lines.append(trimmedNote)
        }
        if includesExchangeConditionSummary {
            lines.append(exchangeConditionSummary)
        }
        if haveOfferKind == .cash {
            lines.append(haveCashSummary.storageLine)
        }
        let joined = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    var haveCashSummary: IndividualListingHaveCashSummary {
        IndividualListingHaveCashSummary(
            pricingMode: haveCashPricingMode,
            amount: haveCashPricingMode == .specifiedAmount ? haveCashAmount : nil
        )
    }

    var exchangeConditionSummary: String {
        IndividualListingExchangeSummary(
            handoffMethod: handoffMethod,
            localPrefecture: localPrefecture,
            localPlaceMemo: localPlaceMemo,
            localSchedule: localSchedule,
            shippingFee: shippingFee,
            shippingDays: shippingDays,
            acceptsOutsideCondition: acceptsOutsideCondition
        )
        .storageLine
    }

    func selectedInventoryItems(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { selectedHaveIDs.contains($0.id) }
    }

    func originalHaveQuantity(for id: UUID) -> Int {
        guard case .edit(let listing) = mode else {
            return 0
        }
        return listing.haves.first(where: { $0.itemID == id })?.quantity ?? 0
    }

    func selectedWishItems(from wishes: [WishItem]) -> [WishItem] {
        wishes.filter { selectedWishIDs.contains($0.id) }
    }

    func optionWishGroupID(selectedWishItems: [WishItem]) -> UUID? {
        switch optionKind {
        case .wish:
            selectedWishItems.first?.groupID
        case .condition:
            conditionGroupID
        case .cash:
            nil
        }
    }

    func optionWishGoodsTypeID(selectedWishItems: [WishItem]) -> UUID? {
        switch optionKind {
        case .wish:
            selectedWishItems.first?.goodsTypeID
        case .condition:
            conditionGoodsTypeID
        case .cash:
            nil
        }
    }

    func hasSameGroupAndType(_ items: [GoodsItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }

    func hasSameGroupAndType(_ items: [WishItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }
}
