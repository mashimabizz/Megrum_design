import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingMatchPolicy {
    static func listingWantsViewerGoods(
        listing: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow]
    ) -> Bool {
        listingHasSelectableWantedOption(
            listing: listing,
            options: options,
            viewerInventory: viewerInventory,
            includesCash: false
        )
    }

    static func listingHasSelectableWantedOption(
        listing _: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        includesCash: Bool
    ) -> Bool {
        options.contains { option in
            if includesCash && option.isCashOffer == true {
                return true
            }
            return viewerInventory.contains { viewerItem in
                optionWantsViewerGoods(option, viewerItem: viewerItem)
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

    static func optionWantsViewerGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        viewerItem: SupabaseHomeGoodsRow
    ) -> Bool {
        guard option.isCashOffer != true else {
            return false
        }
        if option.wishIds.contains(viewerItem.id) {
            return true
        }
        guard option.wishGroupId != nil || option.wishGoodsTypeId != nil else {
            return false
        }
        return HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGroupId, viewerItem.groupId)
            && HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
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
