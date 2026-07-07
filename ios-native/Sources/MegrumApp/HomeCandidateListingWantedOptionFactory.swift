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

        let rowsByID = Self.rowsByID(previewInventory)
        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory,
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
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
            tentativeGoodsIDs: Self.tentativeGoodsIDs(
                option: option,
                matchingItems: matchingItems,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            ),
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

        let rowsByID = Self.rowsByID(previewInventory)
        let matchingItems = HomeCandidateListingWantedOptionMatchPolicy.matchingItems(
            for: option,
            in: viewerInventory,
            wantedRowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
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
            tentativeGoodsIDs: Self.tentativeGoodsIDs(
                option: option,
                matchingItems: matchingItems,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            ),
            titlePreviewItems: previews,
            previewItems: previews,
            subtitleMatchingCount: max(matchingItems.count, previews.count)
        )
    }

    /// matchingItems のうち、確度が不確定（メンバー・種別・シリーズが無記載）な分のID。iter1226.363。
    private static func tentativeGoodsIDs(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [UUID] {
        matchingItems
            .filter { item in
                HomeMutualMatchListingEvaluator.mutualOptionMatchConfidence(
                    option,
                    counterpartItem: item,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                ) == .tentative
            }
            .map(\.id)
    }

    private static func rowsByID(_ rows: [SupabaseHomeGoodsRow]) -> [UUID: SupabaseHomeGoodsRow] {
        Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
        tentativeGoodsIDs: [UUID] = [],
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
            tentativeGoodsIDs: tentativeGoodsIDs,
            previewItems: previewItems,
            groupID: option.wishGroupId,
            goodsTypeID: option.wishGoodsTypeId
        )
    }

}
