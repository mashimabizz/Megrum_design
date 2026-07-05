import Foundation
import MegrumData

struct HomeCandidatePartnerDemandSummary {
    let wishHitCount: Int
    let listingHitCount: Int
    let wishMatchedOfferGoodsIDs: [UUID]
    let individualListingSelection: HomeIndividualListingSelectionContext?
    /// 相手の探し物（合致なし時の需要行「〜を探し中」用）。相手のほしいもの先頭から生成。
    let partnerLookingForText: String?

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
        partnerLookingForText = Self.lookingForText(from: partnerWishesForCandidate)
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

    /// 「サナのトレカ」のような相手の探し物の短文。メンバー＋種別 > 種別 > タイトルの順で組む。
    private static func lookingForText(from partnerWishes: [SupabaseHomeGoodsRow]) -> String? {
        guard let wish = partnerWishes.first else {
            return nil
        }
        let member = wish.characterName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        let goodsType = wish.goodsTypeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        switch (member, goodsType) {
        case let (member?, goodsType?):
            return "\(member)の\(goodsType)"
        case let (member?, nil):
            return "\(member)のグッズ"
        case let (nil, goodsType?):
            return goodsType
        case (nil, nil):
            return wish.title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        }
    }
}
