import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateComposer {
    static func sections(
        from composition: SupabaseHomeComposition,
        viewerOshiSelections: [UserOshiSelection] = []
    ) -> HomeCandidateSections {
        let context = HomeCandidateCompositionContext(
            composition: composition,
            viewerOshiSelections: viewerOshiSelections
        )
        let mutualMatchCandidates = mutualMatchCandidates(
            from: context.partnerScope.filteredComposition(from: composition),
            tagsByInventoryID: context.tagsByInventoryID,
            listingOptionsByListingID: context.listingOptionsByListingID,
            partnerUsersByID: context.partnerScope.usersByID
        )

        var sectionsBuilder = HomeCandidateSectionsBuilder()

        for candidate in sortedCandidates(context.partnerScope.inventory) where HomeCandidateRowMapper.isMarketAvailable(candidate) {
            sectionsBuilder.addPartnerCandidate(candidate, context: context)
        }

        for viewerItem in context.viewerInventory where HomeCandidateRowMapper.isMarketAvailable(viewerItem) {
            sectionsBuilder.addViewerItem(viewerItem, context: context)
        }

        return sectionsBuilder.sections(
            mutualMatchCandidates: mutualMatchCandidates
        )
    }

    static func wishRow(_ wish: SupabaseHomeGoodsRow, matches item: SupabaseHomeGoodsRow) -> Bool {
        HomeCandidateGoodsMatchPolicy.wishRow(wish, matches: item)
    }

    static func wishRowHasSameConfirmedCharacter(
        _ wish: SupabaseHomeGoodsRow,
        _ item: SupabaseHomeGoodsRow
    ) -> Bool {
        HomeCandidateGoodsMatchPolicy.wishRowHasSameConfirmedCharacter(wish, item)
    }

}
