import Foundation
import MegrumData

enum HomeCandidateViewerOfferSignalsBuilder {
    static func signals(
        viewerItem: SupabaseHomeGoodsRow,
        context: HomeCandidateCompositionContext
    ) -> HomeCandidateConditionSignals {
        let matchingPartnerWishes = context.partnerScope.wishes.filter { partnerWish in
            HomeCandidateComposer.wishRow(partnerWish, matches: viewerItem)
        }
        let wishMatchedPartnerUserIDs = HomeCandidateComposer.orderedUnique(matchingPartnerWishes.map(\.userId))
        let matchingPartnerListings = context.partnerScope.listings.filter { listing in
            HomeCandidateListingMatchPolicy.listingWantsViewerGoods(
                listing: listing,
                options: context.listingOptionsByListingID[listing.id, default: []],
                viewerInventory: [viewerItem]
            )
        }
        let matchingPartnerListingOptions = matchingPartnerListings.flatMap { listing in
            context.listingOptionsByListingID[listing.id, default: []].filter { option in
                HomeCandidateListingMatchPolicy.optionWantsViewerGoods(option, viewerItem: viewerItem)
            }
        }
        let orderedPartnerIDs = HomeCandidateComposer.orderedUnique(
            matchingPartnerWishes.map(\.userId) + matchingPartnerListings.map(\.userId)
        )
        let paymentSignals = HomeCandidatePaymentPolicy.signals(
            viewerMethods: context.viewerUser?.paymentMethods,
            partnerMethodsList: orderedPartnerIDs.map { context.partnerScope.usersByID[$0]?.paymentMethods }
        )
        let partnerAllowsMail = matchingPartnerWishes.contains {
            HomeCandidateComposer.exchangeAllowsMail($0.exchangeType)
        } || matchingPartnerListingOptions.contains {
            HomeCandidateComposer.exchangeAllowsMail($0.exchangeType)
        }
        let partnerAllowsLocal = matchingPartnerWishes.contains {
            HomeCandidateComposer.exchangeAllowsLocal($0.exchangeType)
        } || matchingPartnerListingOptions.contains {
            HomeCandidateComposer.exchangeAllowsLocal($0.exchangeType)
        }
        let partnerLocalPrefectureNames = orderedPartnerIDs.compactMap { partnerID in
            context.partnerScope.usersByID[partnerID]?.primaryArea
        }
        let partnerLocalPrefectures = Set(
            partnerLocalPrefectureNames.compactMap(HomeCandidateComposer.normalizedArea)
        )
        let partnerLocalDateKeys = HomeCandidateComposer.localDateKeys(
            from: orderedPartnerIDs.flatMap { partnerID in
                context.partnerScope.activityWindowsByUser[partnerID, default: []]
            }
        )
        let partnerExchangeMethodTitle = HomeCandidateComposer.exchangeMethodTitle(
            allowsLocal: partnerAllowsLocal,
            allowsMail: partnerAllowsMail
        )
        let partnerLocalConditionText = HomeCandidateComposer.localConditionText(
            prefectures: partnerLocalPrefectureNames,
            dateKeys: partnerLocalDateKeys
        )
        let prefectureMatches = orderedPartnerIDs.contains { partnerID in
            HomeCandidateComposer.prefecturesMatch(
                context.viewerUser?.primaryArea,
                context.partnerScope.usersByID[partnerID]?.primaryArea
            )
        }
        let individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
            listings: matchingPartnerListings,
            optionsByListingID: context.listingOptionsByListingID,
            viewerInventory: [viewerItem],
            listingInventory: context.partnerScope.inventory,
            listingWantedInventory: context.partnerScope.wishes + [viewerItem],
            tagsByInventoryID: context.tagsByInventoryID
        )

        return HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: !matchingPartnerListings.isEmpty,
                hasWishHit: !matchingPartnerWishes.isEmpty
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: HomeCandidateComposer.exchangeAllowsMail(viewerItem.exchangeType) && partnerAllowsMail,
                localExchangeSelected: HomeCandidateComposer.exchangeAllowsLocal(viewerItem.exchangeType) && partnerAllowsLocal,
                prefectureMatches: prefectureMatches,
                dateMatches: false,
                partnerExchangeMethodTitle: partnerExchangeMethodTitle,
                partnerLocalConditionText: partnerAllowsLocal ? partnerLocalConditionText : nil,
                partnerLocalPrefectures: partnerLocalPrefectures,
                partnerLocalDateKeys: partnerLocalDateKeys
            ),
            payment: paymentSignals,
            linkCounts: HomeCandidateLinkCounts(
                wishCount: matchingPartnerWishes.count,
                listingCount: matchingPartnerListings.count
            ),
            individualListingSelection: individualListingSelection,
            wishMatchedOfferGoodsIDs: matchingPartnerWishes.isEmpty ? [] : [viewerItem.id],
            wishMatchedPartnerUserIDs: wishMatchedPartnerUserIDs,
            tagMatchCount: HomeCandidateTagMatcher.count(
                itemID: viewerItem.id,
                matchingRows: matchingPartnerWishes,
                tagsByInventoryID: context.tagsByInventoryID
            )
        )
    }
}
