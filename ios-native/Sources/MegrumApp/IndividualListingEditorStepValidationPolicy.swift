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
            if exceedsOptionLimit(draft: draft, wishes: wishes, stagedOptions: stagedOptions) {
                return "選択肢は最大5件までです"
            }
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

    /// 追加済み＋編集中の選択肢が上限（5件）を超えるか。
    static func exceedsOptionLimit(
        draft: IndividualListingDraft,
        wishes: [WishItem],
        stagedOptions: [IndividualListingOptionInput]
    ) -> Bool {
        let currentCount = draft.currentOptionInput(wishes: wishes) == nil ? 0 : 1
        return stagedOptions.count + currentCount > 5
    }
}
