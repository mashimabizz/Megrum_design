import Foundation
import MegrumCore

extension IndividualListingDraft {
    /// 現在編集中タブの選択内容を選択肢1件として取り出す。
    /// Wishタブで未選択・条件タブで未設定なら「未入力」として nil を返す
    /// （追加済みの選択肢だけで先へ進める）。定価タブは選択中とみなす。
    func currentOptionInput(wishes: [WishItem]) -> IndividualListingOptionInput? {
        switch optionKind {
        case .wish:
            let items = selectedWishItems(from: wishes)
            guard !items.isEmpty else {
                return nil
            }
            return IndividualListingOptionInput(
                wishItems: items.map { item in
                    ListingItemQuantity(itemID: item.id, quantity: wishQuantity(for: item.id))
                },
                wishLogic: wishLogic,
                wishMinimumCount: wishLogic == .atLeast ? resolvedWishMinimumCount : 1,
                exchangeType: exchangeType,
                wishGroupID: items.first?.groupID,
                wishGoodsTypeID: items.first?.goodsTypeID
            )
        case .condition:
            guard let conditionGroupID, let conditionGoodsTypeID else {
                return nil
            }
            return IndividualListingOptionInput(
                wishLogic: wishLogic,
                wishMinimumCount: wishLogic == .atLeast ? resolvedWishMinimumCount : 1,
                exchangeType: exchangeType,
                wishGroupID: conditionGroupID,
                wishGoodsTypeID: conditionGoodsTypeID
            )
        case .cash:
            return IndividualListingOptionInput(
                wishLogic: wishLogic,
                wishMinimumCount: 1,
                exchangeType: exchangeType,
                isCashOffer: true,
                cashAmount: cashPricingMode == .specifiedAmount ? cashAmount : nil
            )
        }
    }

    func validationMessage(
        inventory: [GoodsItem],
        wishes: [WishItem],
        stagedOptions: [IndividualListingOptionInput] = []
    ) -> String? {
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
            if haveLogic == .atLeast, selectedHaveIDs.count < 2 {
                return "「何個以上」は2件以上選んだ時に設定できます"
            }
        case .cash:
            if haveCashPricingMode == .specifiedAmount, haveCashAmount <= 0 {
                return "金額を入力してください"
            }
        }

        // 編集中の選択肢に入力があれば、その内容だけを検証する。
        switch optionKind {
        case .wish:
            if !selectedWishIDs.isEmpty {
                let selectedWishItems = selectedWishItems(from: wishes)
                if selectedWishItems.count != selectedWishIDs.count {
                    return "選択したほしいものを読み込めませんでした"
                }
                if wishLogic == .atLeast, selectedWishIDs.count < 2 {
                    return "「何個以上」は2件以上選んだ時に設定できます"
                }
                if haveLogic == .one, wishLogic == .one, selectedHaveIDs.count > 1, selectedWishIDs.count > 1 {
                    return "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
                }
            }
        case .condition:
            break
        case .cash:
            if cashPricingMode == .specifiedAmount, cashAmount <= 0 {
                return "金額を入力してください"
            }
        }

        // 追加済み＋編集中で選択肢が1件もなければ進めない。
        if stagedOptions.isEmpty, currentOptionInput(wishes: wishes) == nil {
            return "求めるものを選択してください"
        }
        return nil
    }

    func createInput(
        inventory: [GoodsItem],
        wishes: [WishItem],
        stagedOptions: [IndividualListingOptionInput] = []
    ) -> IndividualListingCreateInput? {
        guard validationMessage(inventory: inventory, wishes: wishes, stagedOptions: stagedOptions) == nil else {
            return nil
        }
        var options = stagedOptions
        if let current = currentOptionInput(wishes: wishes) {
            options.append(current)
        }
        guard let primary = options.first else {
            return nil
        }
        return IndividualListingCreateInput(
            haveItems: haveOfferKind == .cash ? [] : selectedInventoryItems(from: inventory).map { item in
                ListingItemQuantity(
                    itemID: item.id,
                    quantity: min(haveQuantity(for: item.id), max(1, maxHaveQuantity(for: item)))
                )
            },
            haveLogic: haveLogic,
            haveMinimumCount: haveLogic == .atLeast ? resolvedHaveMinimumCount : 1,
            haveIsCashOffer: haveOfferKind == .cash,
            haveCashAmount: haveOfferKind == .cash && haveCashPricingMode == .specifiedAmount ? haveCashAmount : nil,
            wishItems: primary.wishItems,
            wishLogic: primary.wishLogic,
            wishMinimumCount: primary.wishMinimumCount,
            exchangeType: primary.exchangeType,
            isCashOffer: primary.isCashOffer,
            cashAmount: primary.cashAmount,
            wishGroupID: primary.wishGroupID,
            wishGoodsTypeID: primary.wishGoodsTypeID,
            additionalOptions: Array(options.dropFirst()),
            note: trimmedNoteWithListingMetadata
        )
    }

    func updatedListing(
        from original: IndividualListing,
        inventory: [GoodsItem],
        wishes: [WishItem],
        stagedOptions: [IndividualListingOptionInput] = []
    ) -> IndividualListing? {
        guard let input = createInput(inventory: inventory, wishes: wishes, stagedOptions: stagedOptions) else {
            return nil
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        let existingOptions = original.options.sorted { $0.position < $1.position }
        let allOptionInputs = [input.primaryOption] + input.additionalOptions
        let options = allOptionInputs.enumerated().map { index, option in
            IndividualListingWishOption(
                id: index == 0 ? (existingOptions.first?.id ?? UUID()) : UUID(),
                listingID: original.id,
                position: index + 1,
                wishes: option.wishItems,
                logic: option.wishLogic,
                minimumCount: option.wishMinimumCount,
                exchangeType: option.exchangeType,
                isCashOffer: option.isCashOffer,
                cashAmount: option.cashAmount,
                wishGroupID: option.wishGroupID,
                wishGoodsTypeID: option.wishGoodsTypeID,
                createdAt: index == 0 ? existingOptions.first?.createdAt : nil,
                updatedAt: Date()
            )
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

}
