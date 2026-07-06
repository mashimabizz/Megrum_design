import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingMatchPolicy {
    static func listingWantsViewerGoods(
        listing: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        wantedRowsByID: [UUID: SupabaseHomeGoodsRow] = [:],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> Bool {
        listingHasSelectableWantedOption(
            listing: listing,
            options: options,
            viewerInventory: viewerInventory,
            wantedRowsByID: wantedRowsByID,
            tagsByInventoryID: tagsByInventoryID,
            includesCash: false
        )
    }

    static func listingHasSelectableWantedOption(
        listing _: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        wantedRowsByID: [UUID: SupabaseHomeGoodsRow] = [:],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> Bool {
        options.contains { option in
            if includesCash && option.isCashOffer == true {
                return true
            }
            return viewerInventory.contains { viewerItem in
                optionWantsViewerGoods(
                    option,
                    viewerItem: viewerItem,
                    wantedRowsByID: wantedRowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
            }
        }
    }

    static func listingIncludesCandidate(
        _ listing: SupabaseHomeListingRow,
        candidate: SupabaseHomeGoodsRow
    ) -> Bool {
        if !listing.haveIds.isEmpty {
            return listing.haveIds.contains(candidate.id)
        }
        if HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, candidate.groupId),
           HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, candidate.goodsTypeId) {
            return true
        }
        return listing.haveGroupId == nil && listing.haveGoodsTypeId == nil
    }

    static func firstSelection(
        listings: [SupabaseHomeListingRow],
        optionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        viewerInventory: [SupabaseHomeGoodsRow],
        listingInventory: [SupabaseHomeGoodsRow] = [],
        listingWantedInventory: [SupabaseHomeGoodsRow] = [],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        candidate: SupabaseHomeGoodsRow? = nil,
        includesCash: Bool = false
    ) -> HomeIndividualListingSelectionContext? {
        HomeCandidateListingSelectionFactory.firstSelection(
            listings: listings,
            optionsByListingID: optionsByListingID,
            viewerInventory: viewerInventory,
            listingInventory: listingInventory,
            listingWantedInventory: listingWantedInventory,
            tagsByInventoryID: tagsByInventoryID,
            candidate: candidate,
            includesCash: includesCash
        )
    }

    /// 選択肢の条件（グループ・種別に加えメンバー指定/除外・シリーズ・数量）を
    /// すべて満たす時だけ「相手があなたのグッズを求めている」と判定する。
    /// 旧実装はグループ＋種別のみで、シリーズや数量が違っても激求/求になっていた。
    static func optionWantsViewerGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        viewerItem: SupabaseHomeGoodsRow,
        wantedRowsByID: [UUID: SupabaseHomeGoodsRow] = [:],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> Bool {
        HomeMutualMatchListingEvaluator.mutualOptionWantsCounterpartGoods(
            option,
            counterpartItem: viewerItem,
            rowsByID: wantedRowsByID,
            tagsByInventoryID: tagsByInventoryID
        )
    }

    static func wantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow] = [],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        HomeCandidateListingWantedOptionFactory.wantedOption(
            from: option,
            viewerInventory: viewerInventory,
            previewInventory: previewInventory,
            tagsByInventoryID: tagsByInventoryID,
            includesCash: includesCash
        )
    }
}
