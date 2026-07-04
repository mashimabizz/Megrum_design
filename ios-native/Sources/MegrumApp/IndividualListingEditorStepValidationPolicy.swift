import MegrumCore

enum IndividualListingEditorStepValidationPolicy {
    static func message(
        for step: IndividualListingEditorStep,
        draft: IndividualListingDraft,
        inventory: [GoodsItem],
        wishes: [WishItem],
        stagedOptions: [IndividualListingOptionInput] = []
    ) -> String? {
        switch step {
        case .haves:
            switch draft.haveOfferKind {
            case .goods:
                return draft.selectedHaveIDs.isEmpty ? "譲るものを選択してください" : nil
            case .cash:
                return draft.haveCashPricingMode == .specifiedAmount && draft.haveCashAmount <= 0 ? "金額を入力してください" : nil
            }
        case .options:
            // 追加済みの選択肢が1件以上あれば、編集中タブが未入力でも先へ進める。
            let hasStagedOptions = !stagedOptions.isEmpty
            switch draft.optionKind {
            case .wish:
                if draft.selectedWishIDs.isEmpty {
                    return hasStagedOptions ? nil : "求めるものを選択してください"
                }
                return nil
            case .condition:
                if draft.conditionGroupID == nil || draft.conditionGoodsTypeID == nil {
                    return hasStagedOptions ? nil : "グループとグッズ種別を選択してください"
                }
                return nil
            case .cash:
                return draft.cashPricingMode == .specifiedAmount && draft.cashAmount <= 0 ? "金額を入力してください" : nil
            }
        case .exchange:
            return draft.validationMessage(inventory: inventory, wishes: wishes, stagedOptions: stagedOptions)
        }
    }
}
