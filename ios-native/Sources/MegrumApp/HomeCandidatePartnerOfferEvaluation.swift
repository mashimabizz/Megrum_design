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
        let partnerWishesForCandidate = context.partnerScope.wishesByUser[candidate.userId, default: []]
        let partnerWishHitRows = partnerWishesForCandidate.filter { partnerWish in
            context.availableViewerInventory.contains { viewerItem in
                HomeCandidateComposer.wishRow(partnerWish, matches: viewerItem)
            }
        }
        let partnerWishMatchedOfferItems = context.availableViewerInventory.filter { viewerItem in
            partnerWishesForCandidate.contains { partnerWish in
                HomeCandidateComposer.wishRow(partnerWish, matches: viewerItem)
            }
        }
        let partnerWishHitCount = partnerWishHitRows.count
        let partnerListingHitCount = context.partnerScope.listingsByUser[candidate.userId, default: []].filter { listing in
            HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: candidate)
                && HomeCandidateListingMatchPolicy.listingHasSelectableWantedOption(
                    listing: listing,
                    options: context.listingOptionsByListingID[listing.id, default: []],
                    viewerInventory: context.availableViewerInventory,
                    includesCash: true
                )
        }.count
        let partnerWishHit = partnerWishHitCount > 0
        let partnerListingHit = partnerListingHitCount > 0
        let partnerWantsViewerGoods = partnerWishHit || partnerListingHit
        let individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
            listings: context.partnerScope.listingsByUser[candidate.userId, default: []],
            optionsByListingID: context.listingOptionsByListingID,
            viewerInventory: context.availableViewerInventory,
            listingInventory: context.partnerScope.inventory,
            listingWantedInventory: partnerWishesForCandidate + context.availableViewerInventory,
            tagsByInventoryID: context.tagsByInventoryID,
            candidate: candidate,
            includesCash: true
        )

        signals = HomeCandidateConditionSignalsBuilder.signals(
            candidate: candidate,
            partnerUser: context.partnerScope.usersByID[candidate.userId],
            partnerActivityWindows: context.partnerScope.activityWindowsByUser[candidate.userId, default: []],
            viewerActivityWindows: context.composition.viewerActivityWindows,
            viewerUser: context.viewerUser,
            viewerAllowsMail: context.viewerAllowsMail,
            viewerAllowsLocal: context.viewerAllowsLocal,
            hasIndividualListingHit: partnerListingHit,
            hasWishHit: partnerWishHit,
            matchesViewerWish: satisfiesViewerWish,
            matchesViewerWishCharacter: satisfiesViewerWishCharacter,
            tagMatchCount: tagMatchCount,
            linkCounts: HomeCandidateLinkCounts(
                wishCount: partnerWishHitCount,
                listingCount: partnerListingHitCount
            ),
            individualListingSelection: individualListingSelection,
            wishMatchedOfferGoodsIDs: partnerWishMatchedOfferItems.map(\.id),
            wishMatchedPartnerUserIDs: partnerWishHit ? [candidate.userId] : [],
            ownerHasMegrumPlus: context.composition.megrumPlusUserIDs.contains(candidate.userId)
        )

        if satisfiesViewerWish && partnerWantsViewerGoods {
            bucket = .matched
        } else if satisfiesViewerWish || partnerWantsViewerGoods {
            bucket = .possible
        } else {
            bucket = .none
        }
    }
}
