import Foundation
import MegrumCore

enum IndividualListingOptionReviewItemFactory {
    static func make(
        title: String,
        source: IndividualListingOptionReviewSource,
        draft: IndividualListingDraft,
        wishes: [WishItem],
        groups: [OshiGroup],
        goodsTypes: [GoodsType],
        characters: [OshiCharacter]
    ) -> IndividualListingOptionReviewItem? {
        switch draft.optionKind {
        case .wish:
            let selectedWishes = wishes.filter { draft.selectedWishIDs.contains($0.id) }
            guard !selectedWishes.isEmpty else {
                return nil
            }
            let wishTitles = selectedWishes
                .map { wish in
                    let quantity = draft.wishQuantity(for: wish.id)
                    return quantity > 1 ? "\(wish.title) x\(quantity)" : wish.title
                }
                .joined(separator: " / ")
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "Wish",
                detail: "\(wishTitles)（\(draft.wishLogic.displayName(minimumCount: draft.resolvedWishMinimumCount))）",
                source: source
            )
        case .condition:
            guard let groupID = draft.conditionGroupID,
                  let goodsTypeID = draft.conditionGoodsTypeID
            else {
                return nil
            }
            let groupName = groups.first { $0.id == groupID }?.name ?? "グループ未設定"
            let goodsTypeName = goodsTypes.first { $0.id == goodsTypeID }?.name ?? "種別未設定"
            let memberText = conditionMemberSummary(draft: draft, characters: characters)
            let tagText = draft.conditionTagNames.isEmpty ? "シリーズ指定なし" : draft.conditionTagNames.map { "#\($0)" }.joined(separator: " / ")
            let amountText = draft.usesConditionLogicChoice ? draft.wishLogic.displayName : "\(draft.conditionQuantity)点"
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "条件",
                detail: "\(groupName) / \(memberText) / \(goodsTypeName) / \(tagText) / \(amountText)",
                source: source
            )
        case .cash:
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "定価",
                detail: draft.cashPricingMode == .specifiedAmount ? "¥\(draft.cashAmount.formatted())" : "定価",
                source: source
            )
        }
    }

    private static func conditionMemberSummary(
        draft: IndividualListingDraft,
        characters: [OshiCharacter]
    ) -> String {
        let selectedMembers = characters.filter { draft.conditionMemberIDs.contains($0.id) }
        guard !selectedMembers.isEmpty else {
            return "メンバー指定なし"
        }
        let names = selectedMembers.prefix(3).map(\.name).joined(separator: "・")
        let suffix = selectedMembers.count > 3 ? " 他\(selectedMembers.count - 3)人" : ""
        return draft.excludesSelectedConditionMembers ? "\(names)\(suffix)以外" : "\(names)\(suffix)"
    }
}
