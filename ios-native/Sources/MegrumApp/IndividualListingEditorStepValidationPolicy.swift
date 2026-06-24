import MegrumCore

enum IndividualListingEditorStepValidationPolicy {
    static func message(
        for step: IndividualListingEditorStep,
        draft: IndividualListingDraft,
        inventory: [GoodsItem],
        wishes: [WishItem]
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
            switch draft.optionKind {
            case .wish:
                return draft.selectedWishIDs.isEmpty ? "求めるものを選択してください" : nil
            case .condition:
                return draft.conditionGroupID == nil || draft.conditionGoodsTypeID == nil ? "グループとグッズ種別を選択してください" : nil
            case .cash:
                return draft.cashPricingMode == .specifiedAmount && draft.cashAmount <= 0 ? "金額を入力してください" : nil
            }
        case .exchange:
            return draft.validationMessage(inventory: inventory, wishes: wishes)
        }
    }
}
