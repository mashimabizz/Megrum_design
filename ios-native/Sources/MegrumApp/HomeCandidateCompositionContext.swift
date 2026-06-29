import Foundation
import MegrumCore
import MegrumData

struct HomeCandidateCompositionContext {
    let composition: SupabaseHomeComposition
    let tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    let viewerInventory: [SupabaseHomeGoodsRow]
    let viewerWishes: [SupabaseHomeGoodsRow]
    let viewerInterests: [HomeCandidateViewerInterest]
    let viewerUser: SupabaseHomeUserRow?
    let listingOptionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]]
    let partnerScope: HomeCandidatePartnerScope
    let availableViewerInventory: [SupabaseHomeGoodsRow]
    let viewerAllowsMail: Bool
    let viewerAllowsLocal: Bool

    init(
        composition: SupabaseHomeComposition,
        viewerOshiSelections: [UserOshiSelection]
    ) {
        self.composition = composition
        tagsByInventoryID = Dictionary(grouping: composition.inventoryTags, by: \.inventoryId)
        viewerInventory = composition.viewerInventory
        viewerWishes = composition.viewerWishes
        viewerInterests = Self.viewerInterests(
            viewerWishes: composition.viewerWishes,
            viewerOshiSelections: viewerOshiSelections
        )
        viewerUser = composition.viewerUser
        listingOptionsByListingID = Dictionary(grouping: composition.listingWishOptions, by: \.listingId)
        partnerScope = HomeCandidatePartnerScope(composition: composition)
        availableViewerInventory = composition.viewerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        viewerAllowsMail = availableViewerInventory.contains {
            HomeCandidateComposer.exchangeAllowsMail($0.exchangeType)
        }
        viewerAllowsLocal = availableViewerInventory.contains {
            HomeCandidateComposer.exchangeAllowsLocal($0.exchangeType)
        }
    }

    private static func viewerInterests(
        viewerWishes: [SupabaseHomeGoodsRow],
        viewerOshiSelections: [UserOshiSelection]
    ) -> [HomeCandidateViewerInterest] {
        guard viewerWishes.isEmpty else {
            return viewerWishes.map(HomeCandidateViewerInterest.wish)
        }
        return HomeCandidateViewerInterest.oshiSelections(viewerOshiSelections)
    }
}
