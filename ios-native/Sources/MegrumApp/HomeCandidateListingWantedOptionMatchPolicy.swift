import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingWantedOptionMatchPolicy {
    static func matchingItems(
        for option: SupabaseHomeListingWishOptionRow,
        in viewerInventory: [SupabaseHomeGoodsRow]
    ) -> [SupabaseHomeGoodsRow] {
        viewerInventory.filter { viewerItem in
            HomeCandidateListingMatchPolicy.optionWantsViewerGoods(option, viewerItem: viewerItem)
        }
    }

    static func isSelectable(
        option: SupabaseHomeListingWishOptionRow,
        logic: ListingLogic,
        matchingItems: [SupabaseHomeGoodsRow]
    ) -> Bool {
        guard !matchingItems.isEmpty else {
            return false
        }
        if logic == .atLeast, matchingItems.count < max(1, option.minCount ?? 1) {
            return false
        }
        return true
    }

    static func hasConfiguredGoodsCondition(_ option: SupabaseHomeListingWishOptionRow) -> Bool {
        !option.wishIds.isEmpty || option.wishGroupId != nil || option.wishGoodsTypeId != nil
    }
}
