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

        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory
        )
        guard HomeCandidateListingWantedOptionMatchPolicy.isSelectable(
            option: option,
            logic: logic,
            matchingItems: matchingItems
        ) else {
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

        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory
        )
        let previews = HomeCandidateListingWantedOptionPreviewBuilder.previewItems(
            for: option,
            matchingItems: matchingItems,
            previewInventory: previewInventory,
            tagsByInventoryID: tagsByInventoryID
        )
        let hasConfiguredCondition = HomeCandidateListingWantedOptionMatchPolicy.hasConfiguredGoodsCondition(option)
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
            title: HomeCandidateListingWantedOptionTextPolicy.title(
                option: option,
                matchingItems: matchingItems,
                previewItems: titlePreviewItems
            ),
            subtitle: HomeCandidateListingWantedOptionTextPolicy.subtitle(
                option: option,
                matchingCount: subtitleMatchingCount ?? matchingItems.count
            ),
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

}
