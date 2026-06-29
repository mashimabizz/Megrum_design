import Foundation
import MegrumData

struct HomeCandidatePartnerDemandSummary {
    let wishHitCount: Int
    let listingHitCount: Int
    let wishMatchedOfferGoodsIDs: [UUID]
    let individualListingSelection: HomeIndividualListingSelectionContext?

    private let partnerUserID: UUID

    var hasWishHit: Bool {
        wishHitCount > 0
    }

    var hasListingHit: Bool {
        listingHitCount > 0
    }

    var partnerWantsViewerGoods: Bool {
        hasWishHit || hasListingHit
    }

    var linkCounts: HomeCandidateLinkCounts {
        HomeCandidateLinkCounts(
            wishCount: wishHitCount,
            listingCount: listingHitCount
        )
    }

    var wishMatchedPartnerUserIDs: [UUID] {
        hasWishHit ? [partnerUserID] : []
    }

    init(candidate: SupabaseHomeGoodsRow, context: HomeCandidateCompositionContext) {
        partnerUserID = candidate.userId

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
        let partnerListingsForCandidate = context.partnerScope.listingsByUser[candidate.userId, default: []]

        wishHitCount = partnerWishHitRows.count
        wishMatchedOfferGoodsIDs = partnerWishMatchedOfferItems.map(\.id)
        listingHitCount = partnerListingsForCandidate.filter { listing in
            HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: candidate)
                && HomeCandidateListingMatchPolicy.listingHasSelectableWantedOption(
                    listing: listing,
                    options: context.listingOptionsByListingID[listing.id, default: []],
                    viewerInventory: context.availableViewerInventory,
                    includesCash: true
                )
        }.count
        individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
            listings: partnerListingsForCandidate,
            optionsByListingID: context.listingOptionsByListingID,
            viewerInventory: context.availableViewerInventory,
            listingInventory: context.partnerScope.inventory,
            listingWantedInventory: partnerWishesForCandidate + context.availableViewerInventory,
            tagsByInventoryID: context.tagsByInventoryID,
            candidate: candidate,
            includesCash: true
        )
    }
}
