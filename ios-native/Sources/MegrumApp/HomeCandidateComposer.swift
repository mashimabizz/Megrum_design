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

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []
        var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

        for candidate in sortedCandidates(context.partnerScope.inventory) where HomeCandidateRowMapper.isMarketAvailable(candidate) {
            let evaluation = HomeCandidatePartnerOfferEvaluation(candidate: candidate, context: context)
            conditionSignalsByItemID[candidate.id] = evaluation.signals

            switch evaluation.bucket {
            case .matched:
                matched.append(evaluation.candidateItem)
            case .possible:
                possible.append(evaluation.candidateItem)
            case .none:
                break
            }
        }

        for viewerItem in context.viewerInventory where HomeCandidateRowMapper.isMarketAvailable(viewerItem) {
            conditionSignalsByItemID[viewerItem.id] = HomeCandidateViewerOfferSignalsBuilder.signals(
                viewerItem: viewerItem,
                context: context
            )
        }

        return HomeCandidateSections(
            matchedItems: deduplicated(matched),
            possibleItems: deduplicated(possible),
            conditionSignalsByItemID: conditionSignalsByItemID,
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
