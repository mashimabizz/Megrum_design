import Foundation
import MegrumData

struct HomeCandidateViewerOfferDemandSummary {
    let wishHitCount: Int
    let listingHitCount: Int
    let wishMatchedOfferGoodsIDs: [UUID]
    /// ほしいもの一致のうち、シリーズ等が無記載で確定できない（＝不確定「？」）分。iter1226.363。
    let wishTentativeOfferGoodsIDs: [UUID]
    let wishMatchedPartnerUserIDs: [UUID]
    let orderedPartnerIDs: [UUID]
    let partnerAllowsMail: Bool
    let partnerAllowsLocal: Bool
    let partnerExchangeMethodTitle: String?
    let partnerLocalConditionText: String?
    let partnerLocalPrefectures: Set<String>
    let partnerLocalDateKeys: Set<String>
    let prefectureMatches: Bool
    let individualListingSelection: HomeIndividualListingSelectionContext?
    let tagMatchCount: Int

    var hasWishHit: Bool {
        wishHitCount > 0
    }

    var hasListingHit: Bool {
        listingHitCount > 0
    }

    var linkCounts: HomeCandidateLinkCounts {
        HomeCandidateLinkCounts(
            wishCount: wishHitCount,
            listingCount: listingHitCount
        )
    }

    init(viewerItem: SupabaseHomeGoodsRow, context: HomeCandidateCompositionContext) {
        // ほしいもの一致は確度（確定/不確定）付きで評価。メンバー・種別・シリーズが無記載なら不確定。iter1226.363。
        let wishMatches = context.partnerScope.wishes.compactMap { partnerWish -> (SupabaseHomeGoodsRow, HomeCandidateMatchConfidence)? in
            guard let confidence = HomeMutualMatchListingEvaluator.wishGoodsConfidence(
                wish: partnerWish,
                item: viewerItem,
                tagsByInventoryID: context.tagsByInventoryID
            ) else {
                return nil
            }
            return (partnerWish, confidence)
        }
        let matchingPartnerWishes = wishMatches.map(\.0)
        let hasConfirmedWish = wishMatches.contains { $0.1 == .confirmed }
        let partnerWishRowsByID = Dictionary(
            context.partnerScope.wishes.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let matchingPartnerListings = context.partnerScope.listings.filter { listing in
            HomeCandidateListingMatchPolicy.listingWantsViewerGoods(
                listing: listing,
                options: context.listingOptionsByListingID[listing.id, default: []],
                viewerInventory: [viewerItem],
                wantedRowsByID: partnerWishRowsByID,
                tagsByInventoryID: context.tagsByInventoryID
            )
        }
        let matchingPartnerListingOptions = matchingPartnerListings.flatMap { listing in
            context.listingOptionsByListingID[listing.id, default: []].filter { option in
                HomeCandidateListingMatchPolicy.optionWantsViewerGoods(
                    option,
                    viewerItem: viewerItem,
                    wantedRowsByID: partnerWishRowsByID,
                    tagsByInventoryID: context.tagsByInventoryID
                )
            }
        }

        wishHitCount = matchingPartnerWishes.count
        listingHitCount = matchingPartnerListings.count
        wishMatchedOfferGoodsIDs = matchingPartnerWishes.isEmpty ? [] : [viewerItem.id]
        // 一致はあるが確定ほしいもの一致が無い＝不確定「？」。
        wishTentativeOfferGoodsIDs = (!matchingPartnerWishes.isEmpty && !hasConfirmedWish) ? [viewerItem.id] : []
        wishMatchedPartnerUserIDs = HomeCandidateComposer.orderedUnique(matchingPartnerWishes.map(\.userId))
        orderedPartnerIDs = HomeCandidateComposer.orderedUnique(
            matchingPartnerWishes.map(\.userId) + matchingPartnerListings.map(\.userId)
        )
        partnerAllowsMail = matchingPartnerWishes.contains {
            HomeCandidateExchangePolicy.allowsMail($0.exchangeType)
        } || matchingPartnerListingOptions.contains {
            HomeCandidateExchangePolicy.allowsMail($0.exchangeType)
        }
        partnerAllowsLocal = matchingPartnerWishes.contains {
            HomeCandidateExchangePolicy.allowsLocal($0.exchangeType)
        } || matchingPartnerListingOptions.contains {
            HomeCandidateExchangePolicy.allowsLocal($0.exchangeType)
        }

        let partnerLocalPrefectureNames = orderedPartnerIDs.compactMap { partnerID in
            context.partnerScope.usersByID[partnerID]?.primaryArea
        }
        partnerLocalPrefectures = Set(
            partnerLocalPrefectureNames.compactMap(HomeCandidateExchangePolicy.normalizedArea)
        )
        partnerLocalDateKeys = HomeCandidateExchangePolicy.localDateKeys(
            from: orderedPartnerIDs.flatMap { partnerID in
                context.partnerScope.activityWindowsByUser[partnerID, default: []]
            }
        )
        partnerExchangeMethodTitle = HomeCandidateExchangePolicy.methodTitle(
            allowsLocal: partnerAllowsLocal,
            allowsMail: partnerAllowsMail
        )
        partnerLocalConditionText = HomeCandidateExchangePolicy.localConditionText(
            prefectures: partnerLocalPrefectureNames,
            dateKeys: partnerLocalDateKeys
        )
        prefectureMatches = orderedPartnerIDs.contains { partnerID in
            HomeCandidateExchangePolicy.prefecturesMatch(
                context.viewerUser?.primaryArea,
                context.partnerScope.usersByID[partnerID]?.primaryArea
            )
        }
        individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
            listings: matchingPartnerListings,
            optionsByListingID: context.listingOptionsByListingID,
            viewerInventory: [viewerItem],
            listingInventory: context.partnerScope.inventory,
            listingWantedInventory: context.partnerScope.wishes + [viewerItem],
            tagsByInventoryID: context.tagsByInventoryID
        )
        tagMatchCount = HomeCandidateTagMatcher.count(
            itemID: viewerItem.id,
            matchingRows: matchingPartnerWishes,
            tagsByInventoryID: context.tagsByInventoryID
        )
    }
}
