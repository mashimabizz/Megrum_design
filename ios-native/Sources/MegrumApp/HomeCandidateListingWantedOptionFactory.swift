import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingWantedOptionFactory {
    static func wantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow] = [],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        let logic = ListingLogic(rawValue: option.logic ?? "") ?? .one
        if option.isCashOffer == true {
            guard includesCash else {
                return nil
            }
            return cashWantedOption(option: option, logic: logic)
        }

        let matchingItems = viewerInventory.filter { viewerItem in
            HomeCandidateListingMatchPolicy.optionWantsViewerGoods(option, viewerItem: viewerItem)
        }
        guard !matchingItems.isEmpty else {
            return nil
        }
        if logic == .atLeast, matchingItems.count < max(1, option.minCount ?? 1) {
            return nil
        }

        return goodsWantedOption(
            option: option,
            logic: logic,
            matchingItems: matchingItems,
            titlePreviewItems: [],
            previewItems: HomeCandidateListingWantedOptionPreviewBuilder.previewItems(
                for: option,
                matchingItems: matchingItems,
                previewInventory: previewInventory,
                tagsByInventoryID: tagsByInventoryID
            )
        )
    }

    static func detailWantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        let logic = ListingLogic(rawValue: option.logic ?? "") ?? .one
        if option.isCashOffer == true {
            guard includesCash else {
                return nil
            }
            return cashWantedOption(option: option, logic: logic)
        }

        let matchingItems = viewerInventory.filter { viewerItem in
            HomeCandidateListingMatchPolicy.optionWantsViewerGoods(option, viewerItem: viewerItem)
        }
        let previews = HomeCandidateListingWantedOptionPreviewBuilder.previewItems(
            for: option,
            matchingItems: matchingItems,
            previewInventory: previewInventory,
            tagsByInventoryID: tagsByInventoryID
        )
        let hasConfiguredCondition = !option.wishIds.isEmpty || option.wishGroupId != nil || option.wishGoodsTypeId != nil
        guard hasConfiguredCondition || !previews.isEmpty else {
            return nil
        }
        return goodsWantedOption(
            option: option,
            logic: logic,
            matchingItems: matchingItems,
            titlePreviewItems: previews,
            previewItems: previews,
            subtitleMatchingCount: max(matchingItems.count, previews.count)
        )
    }

    private static func cashWantedOption(
        option: SupabaseHomeListingWishOptionRow,
        logic: ListingLogic
    ) -> HomeIndividualListingWantedOption {
        HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: TradeAmountFormatter.fixedPrice(amount: option.cashAmount),
            subtitle: "金額で受け取る条件",
            logic: logic,
            kind: .cash,
            cashAmount: option.cashAmount
        )
    }

    private static func goodsWantedOption(
        option: SupabaseHomeListingWishOptionRow,
        logic: ListingLogic,
        matchingItems: [SupabaseHomeGoodsRow],
        titlePreviewItems: [HomeIndividualListingWantedPreviewItem],
        previewItems: [HomeIndividualListingWantedPreviewItem],
        subtitleMatchingCount: Int? = nil
    ) -> HomeIndividualListingWantedOption {
        let kind: HomeIndividualListingWantedOption.Kind = option.wishIds.isEmpty ? .condition : .goods
        return HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: wantedOptionTitle(option: option, matchingItems: matchingItems, previewItems: titlePreviewItems),
            subtitle: wantedOptionSubtitle(option: option, matchingCount: subtitleMatchingCount ?? matchingItems.count),
            logic: logic,
            minimumCount: option.minCount ?? 1,
            kind: kind,
            goodsIDs: option.wishIds,
            matchingGoodsIDs: matchingItems.map(\.id),
            previewItems: previewItems,
            groupID: option.wishGroupId,
            goodsTypeID: option.wishGoodsTypeId
        )
    }

    private static func wantedOptionTitle(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        previewItems: [HomeIndividualListingWantedPreviewItem] = []
    ) -> String {
        if let previewTitle = previewItems.first?.title {
            return previewTitle
        }
        if !option.wishIds.isEmpty {
            if let exactItem = matchingItems.first(where: { option.wishIds.contains($0.id) }) {
                return exactItem.title
            }
            return matchingItems.first?.title ?? "グッズ指定"
        }
        if let first = matchingItems.first {
            return first.title
        }
        return "条件指定"
    }

    private static func wantedOptionSubtitle(
        option: SupabaseHomeListingWishOptionRow,
        matchingCount: Int
    ) -> String? {
        if option.wishIds.count > 1 {
            if ListingLogic(rawValue: option.logic ?? "") == .atLeast {
                return ListingLogic.minimumCountTitle(option.minCount ?? 1)
            }
            return "\(option.wishIds.count)点から選択"
        }
        if option.wishGroupId != nil || option.wishGoodsTypeId != nil {
            return "\(matchingCount)件の候補"
        }
        return nil
    }

}
