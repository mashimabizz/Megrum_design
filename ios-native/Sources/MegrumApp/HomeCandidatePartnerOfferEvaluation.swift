import Foundation
import MegrumCore
import MegrumData

struct HomeCandidatePartnerOfferEvaluation {
    enum Bucket {
        case matched
        case possible
        case none
    }

    let candidateItem: GoodsItem
    let signals: HomeCandidateConditionSignals
    let bucket: Bucket

    init(candidate: SupabaseHomeGoodsRow, context: HomeCandidateCompositionContext) {
        candidateItem = HomeCandidateRowMapper.makeGoodsItem(
            from: candidate,
            tags: context.tagsByInventoryID[candidate.id] ?? [],
            ownerUser: context.partnerScope.usersByID[candidate.userId],
            ownerHasMegrumPlus: context.composition.megrumPlusUserIDs.contains(candidate.userId)
        )

        let matchingViewerWishes = context.viewerWishes.filter { wish in
            HomeCandidateComposer.wishRow(wish, matches: candidate)
        }
        let matchingViewerInterests = context.viewerInterests.filter { interest in
            interest.matches(candidate)
        }
        let satisfiesViewerWish = !matchingViewerInterests.isEmpty
        let satisfiesViewerWishCharacter = matchingViewerInterests.contains { interest in
            interest.matchesMemberShelf(candidate)
        }
        let tagMatchCount = HomeCandidateTagMatcher.count(
            itemID: candidate.id,
            matchingRows: matchingViewerWishes,
            tagsByInventoryID: context.tagsByInventoryID
        )
        let partnerDemand = HomeCandidatePartnerDemandSummary(candidate: candidate, context: context)

        signals = HomeCandidateConditionSignalsBuilder.signals(
            candidate: candidate,
            partnerUser: context.partnerScope.usersByID[candidate.userId],
            partnerActivityWindows: context.partnerScope.activityWindowsByUser[candidate.userId, default: []],
            viewerActivityWindows: context.composition.viewerActivityWindows,
            viewerUser: context.viewerUser,
            viewerAllowsMail: context.viewerAllowsMail,
            viewerAllowsLocal: context.viewerAllowsLocal,
            hasIndividualListingHit: partnerDemand.hasListingHit,
            hasWishHit: partnerDemand.hasWishHit,
            matchesViewerWish: satisfiesViewerWish,
            matchesViewerWishCharacter: satisfiesViewerWishCharacter,
            tagMatchCount: tagMatchCount,
            linkCounts: partnerDemand.linkCounts,
            individualListingSelection: partnerDemand.individualListingSelection,
            wishMatchedOfferGoodsIDs: partnerDemand.wishMatchedOfferGoodsIDs,
            wishMatchedPartnerUserIDs: partnerDemand.wishMatchedPartnerUserIDs,
            ownerHasMegrumPlus: context.composition.megrumPlusUserIDs.contains(candidate.userId),
            partnerLookingForText: partnerDemand.partnerLookingForText
        )

        if satisfiesViewerWish && partnerDemand.partnerWantsViewerGoods {
            bucket = .matched
        } else if satisfiesViewerWish || partnerDemand.partnerWantsViewerGoods {
            bucket = .possible
        } else {
            bucket = .none
        }
    }
}
