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
        let payload = draft.currentOptionInput(wishes: wishes)
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
                kind: "ほしいもの",
                detail: "\(wishTitles)（\(draft.wishLogic.displayName(minimumCount: draft.resolvedWishMinimumCount))）",
                source: source,
                payload: payload
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
                source: source,
                payload: payload
            )
        case .cash:
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "定価",
                detail: draft.cashPricingMode == .specifiedAmount ? "¥\(draft.cashAmount.formatted())" : "定価",
                source: source,
                payload: payload
            )
        }
    }

    /// 既存の個別募集の選択肢を、編集画面の「追加済み選択肢」として読み込む。
    static func make(
        from option: IndividualListingWishOption,
        title: String,
        wishes: [WishItem],
        groups: [OshiGroup],
        goodsTypes: [GoodsType]
    ) -> IndividualListingOptionReviewItem {
        let payload = IndividualListingOptionInput(option: option)
        if option.isCashOffer {
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "定価",
                detail: option.cashAmount.map { "¥\($0.formatted())" } ?? "定価",
                source: .staged,
                payload: payload
            )
        }
        if option.wishes.isEmpty {
            let groupName = groups.first { $0.id == option.wishGroupID }?.name ?? "グループ未設定"
            let goodsTypeName = goodsTypes.first { $0.id == option.wishGoodsTypeID }?.name ?? "種別未設定"
            return IndividualListingOptionReviewItem(
                title: title,
                kind: "条件",
                detail: "\(groupName) / \(goodsTypeName)",
                source: .staged,
                payload: payload
            )
        }
        let titles = option.wishes.compactMap { entry -> String? in
            guard let wish = wishes.first(where: { $0.id == entry.itemID }) else {
                return nil
            }
            return entry.quantity > 1 ? "\(wish.title) x\(entry.quantity)" : wish.title
        }
        let detail = titles.isEmpty
            ? "ほしいもの\(option.wishes.count)件（\(option.logic.displayName(minimumCount: option.minimumCount))）"
            : "\(titles.joined(separator: " / "))（\(option.logic.displayName(minimumCount: option.minimumCount))）"
        return IndividualListingOptionReviewItem(
            title: title,
            kind: "ほしいもの",
            detail: detail,
            source: .staged,
            payload: payload
        )
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
