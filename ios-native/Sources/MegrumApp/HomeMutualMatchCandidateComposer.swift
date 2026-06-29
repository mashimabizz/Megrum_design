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
        let rowsByID = goodsRowsByID(
            composition.viewerInventory
                + composition.viewerWishes
                + composition.partnerInventory
                + composition.partnerWishes
        )
        var result: [HomeMutualMatchCandidateData] = []
        var seenCandidateIDs: Set<UUID> = []

        for viewerListing in activeListings(composition.viewerListings) {
            let viewerOffers = offeredRows(for: viewerListing, inventory: viewerInventory)
            guard !viewerOffers.isEmpty else {
                continue
            }

            for partnerListing in activeListings(composition.partnerListings) {
                let partnerOffers = offeredRows(for: partnerListing, inventory: partnerInventory)
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
                let partnerGoodsItems = HomeMutualMatchCandidatePresentation.goodsItems(
                    rows: partnerGoods,
                    tagsByInventoryID: tagsByInventoryID,
                    ownerUser: partnerUser
                )
                let viewerGoodsItems = HomeMutualMatchCandidatePresentation.goodsItems(
                    rows: viewerGoods,
                    tagsByInventoryID: tagsByInventoryID,
                    ownerUser: composition.viewerUser
                )
                let partnerDisplayItems = HomeMutualMatchCandidatePresentation.displayItems(
                    goodsItems: partnerGoodsItems,
                    cashOptions: receiveSide.matchedCashOptions
                )
                let viewerDisplayItems = HomeMutualMatchCandidatePresentation.displayItems(
                    goodsItems: viewerGoodsItems,
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
                        partnerGoodsItems: partnerGoodsItems,
                        viewerGoodsItems: viewerGoodsItems,
                        partnerDisplayItems: partnerDisplayItems,
                        viewerDisplayItems: viewerDisplayItems,
                        signals: signals,
                        conditionSignalsByPartnerGoodsID: Dictionary(
                            uniqueKeysWithValues: partnerGoodsItems.map { ($0.id, signals) }
                        ),
                        attentionKinds: attentionKinds
                    )
                )
            }
        }

        return result
            .sorted { lhs, rhs in
                let lhsScore = HomeMutualMatchCandidateSignals.attentionScore(lhs.attentionKinds)
                let rhsScore = HomeMutualMatchCandidateSignals.attentionScore(rhs.attentionKinds)
                if lhsScore == rhsScore {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhsScore < rhsScore
            }
            .prefix(12)
            .map { $0 }
    }

    private static func activeListings(_ listings: [SupabaseHomeListingRow]) -> [SupabaseHomeListingRow] {
        listings.filter { listing in
            guard let status = listing.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !status.isEmpty
            else {
                return true
            }
            return status == IndividualListingStatus.active.rawValue
        }
    }

    private static func offeredRows(
        for listing: SupabaseHomeListingRow,
        inventory: [SupabaseHomeGoodsRow]
    ) -> [SupabaseHomeGoodsRow] {
        if !listing.haveIds.isEmpty {
            return inventory.filter { listing.haveIds.contains($0.id) }
        }
        guard listing.haveGroupId != nil || listing.haveGoodsTypeId != nil else {
            return []
        }
        return inventory.filter { row in
            HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, row.groupId)
                && HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, row.goodsTypeId)
        }
    }

    private static func goodsRowsByID(_ rows: [SupabaseHomeGoodsRow]) -> [UUID: SupabaseHomeGoodsRow] {
        rows.reduce(into: [UUID: SupabaseHomeGoodsRow]()) { result, row in
            result[row.id] = result[row.id] ?? row
        }
    }
}
