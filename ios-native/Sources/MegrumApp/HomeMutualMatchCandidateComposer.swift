import Foundation
import MegrumCore
import MegrumData

extension HomeCandidateComposer {
    static func mutualMatchCandidates(
        from composition: SupabaseHomeComposition,
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]],
        listingOptionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        partnerUsersByID: [UUID: SupabaseHomeUserRow]
    ) -> [HomeMutualMatchCandidateData] {
        let viewerInventory = composition.viewerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let partnerInventory = composition.partnerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let rowsByID = HomeMutualMatchListingInputResolver.goodsRowsByID(
            composition.viewerInventory
                + composition.viewerWishes
                + composition.partnerInventory
                + composition.partnerWishes
        )
        var result: [HomeMutualMatchCandidateData] = []
        var seenCandidateIDs: Set<UUID> = []

        let viewerListings = HomeMutualMatchListingInputResolver.activeListings(composition.viewerListings)
        let partnerListings = HomeMutualMatchListingInputResolver.activeListings(composition.partnerListings)

        for viewerListing in viewerListings {
            let viewerOffers = HomeMutualMatchListingInputResolver.offeredRows(
                for: viewerListing,
                inventory: viewerInventory
            )
            guard !viewerOffers.isEmpty else {
                continue
            }

            for partnerListing in partnerListings {
                let partnerOffers = HomeMutualMatchListingInputResolver.offeredRows(
                    for: partnerListing,
                    inventory: partnerInventory
                )
                guard !partnerOffers.isEmpty else {
                    continue
                }

                let viewerOptions = HomeCandidateListingOptionOrdering.sorted(
                    listingOptionsByListingID[viewerListing.id, default: []]
                )
                let partnerOptions = HomeCandidateListingOptionOrdering.sorted(
                    listingOptionsByListingID[partnerListing.id, default: []]
                )
                let receiveSide = HomeMutualMatchListingEvaluator.evaluateWantedSide(
                    options: viewerOptions,
                    counterpartOffers: partnerOffers,
                    counterpartCashOptions: partnerOptions,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
                guard receiveSide.isSatisfied else {
                    continue
                }

                let giveSide = HomeMutualMatchListingEvaluator.evaluateWantedSide(
                    options: partnerOptions,
                    counterpartOffers: viewerOffers,
                    counterpartCashOptions: viewerOptions,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
                guard giveSide.isSatisfied else {
                    continue
                }

                let partnerGoods = receiveSide.matchedGoods.isEmpty ? partnerOffers : receiveSide.matchedGoods
                let viewerGoods = giveSide.matchedGoods.isEmpty ? viewerOffers : giveSide.matchedGoods
                guard let firstPartnerGoods = partnerGoods.first else {
                    continue
                }

                let partnerUser = partnerUsersByID[partnerListing.userId]
                let exchangeEvaluation = HomeMutualMatchConditionPolicy.exchangeEvaluation(
                    viewerListing: viewerListing,
                    viewerUser: composition.viewerUser,
                    partnerListing: partnerListing,
                    partnerUser: partnerUser
                )
                let requiresPayment = !receiveSide.matchedCashOptions.isEmpty
                    || !giveSide.matchedCashOptions.isEmpty
                let paymentEvaluation = HomeMutualMatchConditionPolicy.paymentEvaluation(
                    viewerMethods: composition.viewerUser?.paymentMethods ?? [],
                    partnerMethods: partnerUser?.paymentMethods ?? [],
                    requiresPayment: requiresPayment
                )
                let attentionKinds = HomeMutualMatchCandidateSignals.attentionKinds(
                    receiveSide: receiveSide,
                    giveSide: giveSide,
                    exchangeKinds: exchangeEvaluation.attentionKinds,
                    paymentKinds: paymentEvaluation.attentionKinds
                )
                let signals = HomeMutualMatchCandidateSignals.make(
                    partnerListing: partnerListing,
                    partnerOptions: partnerOptions,
                    viewerOffers: viewerOffers,
                    exchange: exchangeEvaluation.signals,
                    payment: paymentEvaluation.signals,
                    tagMatchCount: HomeCandidateTagMatcher.count(
                        itemID: firstPartnerGoods.id,
                        matchingRows: viewerGoods,
                        tagsByInventoryID: tagsByInventoryID
                    )
                )
                let partnerSide = HomeMutualMatchCandidatePresentation.displaySide(
                    rows: partnerGoods,
                    tagsByInventoryID: tagsByInventoryID,
                    ownerUser: partnerUser,
                    cashOptions: receiveSide.matchedCashOptions
                )
                let viewerSide = HomeMutualMatchCandidatePresentation.displaySide(
                    rows: viewerGoods,
                    tagsByInventoryID: tagsByInventoryID,
                    ownerUser: composition.viewerUser,
                    cashOptions: giveSide.matchedCashOptions
                )
                let candidateID = HomeMutualMatchCandidatePresentation.stableID(
                    viewerListingID: viewerListing.id,
                    partnerListingID: partnerListing.id
                )
                guard seenCandidateIDs.insert(candidateID).inserted else {
                    continue
                }

                result.append(
                    HomeMutualMatchCandidateData(
                        id: candidateID,
                        partnerID: partnerListing.userId,
                        partnerName: HomeMutualMatchCandidatePresentation.displayName(
                            for: partnerUser,
                            fallbackID: partnerListing.userId
                        ),
                        partnerHandle: HomeMutualMatchCandidatePresentation.handle(
                            for: partnerUser,
                            fallbackID: partnerListing.userId
                        ),
                        partnerInitial: HomeMutualMatchCandidatePresentation.initial(
                            for: partnerUser,
                            fallbackID: partnerListing.userId
                        ),
                        partnerArea: partnerUser?.primaryArea ?? "地域未設定",
                        partnerOshiText: HomeMutualMatchCandidatePresentation.oshiText(for: firstPartnerGoods),
                        partnerAgeRangeText: HomeMutualMatchCandidatePresentation.ageRangeText(for: partnerUser?.age),
                        partnerEvaluationSummaryText: HomeMutualMatchCandidatePresentation.evaluationSummaryText(
                            for: partnerUser
                        ),
                        partnerGoodsItems: partnerSide.goodsItems,
                        viewerGoodsItems: viewerSide.goodsItems,
                        partnerDisplayItems: partnerSide.displayItems,
                        viewerDisplayItems: viewerSide.displayItems,
                        signals: signals,
                        conditionSignalsByPartnerGoodsID: Dictionary(
                            uniqueKeysWithValues: partnerSide.goodsItems.map { ($0.id, signals) }
                        ),
                        attentionKinds: attentionKinds
                    )
                )
            }
        }

        return HomeMutualMatchCandidateOrdering.prioritized(result)
    }

}
