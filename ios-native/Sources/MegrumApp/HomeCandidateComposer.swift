import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateComposer {
    static func sections(
        from composition: SupabaseHomeComposition,
        viewerOshiSelections: [UserOshiSelection] = []
    ) -> HomeCandidateSections {
        let tagsByInventoryID = Dictionary(grouping: composition.inventoryTags, by: \.inventoryId)
        let viewerInventory = composition.viewerInventory
        let viewerWishes = composition.viewerWishes
        let viewerInterests = viewerInterests(
            viewerWishes: viewerWishes,
            viewerOshiSelections: viewerOshiSelections
        )
        let viewerUser = composition.viewerUser
        let listingOptionsByListingID = Dictionary(grouping: composition.listingWishOptions, by: \.listingId)
        let partnerScope = HomeCandidatePartnerScope(composition: composition)
        let availableViewerInventory = viewerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let viewerAllowsMail = availableViewerInventory.contains { exchangeAllowsMail($0.exchangeType) }
        let viewerAllowsLocal = availableViewerInventory.contains { exchangeAllowsLocal($0.exchangeType) }
        let mutualMatchCandidates = mutualMatchCandidates(
            from: partnerScope.filteredComposition(from: composition),
            tagsByInventoryID: tagsByInventoryID,
            listingOptionsByListingID: listingOptionsByListingID,
            partnerUsersByID: partnerScope.usersByID
        )

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []
        var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

        for candidate in sortedCandidates(partnerScope.inventory) where HomeCandidateRowMapper.isMarketAvailable(candidate) {
            let candidateItem = HomeCandidateRowMapper.makeGoodsItem(
                from: candidate,
                tags: tagsByInventoryID[candidate.id] ?? [],
                ownerUser: partnerScope.usersByID[candidate.userId],
                ownerHasMegrumPlus: composition.megrumPlusUserIDs.contains(candidate.userId)
            )
            let matchingViewerWishes = viewerWishes.filter { wish in
                wishRow(wish, matches: candidate)
            }
            let matchingViewerInterests = viewerInterests.filter { interest in
                interest.matches(candidate)
            }
            let satisfiesViewerWish = !matchingViewerInterests.isEmpty
            let satisfiesViewerWishCharacter = matchingViewerInterests.contains { interest in
                interest.matchesMemberShelf(candidate)
            }
            let tagMatchCount = HomeCandidateTagMatcher.count(
                itemID: candidate.id,
                matchingRows: matchingViewerWishes,
                tagsByInventoryID: tagsByInventoryID
            )
            let partnerWishesForCandidate = partnerScope.wishesByUser[candidate.userId, default: []]
            let partnerWishHitRows = partnerWishesForCandidate.filter { partnerWish in
                availableViewerInventory.contains { viewerItem in
                    wishRow(partnerWish, matches: viewerItem)
                }
            }
            let partnerWishMatchedOfferItems = availableViewerInventory.filter { viewerItem in
                partnerWishesForCandidate.contains { partnerWish in
                    wishRow(partnerWish, matches: viewerItem)
                }
            }
            let partnerWishHitCount = partnerWishHitRows.count
            let partnerListingHitCount = partnerScope.listingsByUser[candidate.userId, default: []].filter { listing in
                HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: candidate)
                    && HomeCandidateListingMatchPolicy.listingHasSelectableWantedOption(
                        listing: listing,
                        options: listingOptionsByListingID[listing.id, default: []],
                        viewerInventory: availableViewerInventory,
                        includesCash: true
                    )
            }.count
            let partnerWishHit = partnerWishHitCount > 0
            let partnerListingHit = partnerListingHitCount > 0
            let partnerWantsViewerGoods = partnerWishHit || partnerListingHit
            let individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
                listings: partnerScope.listingsByUser[candidate.userId, default: []],
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: availableViewerInventory,
                listingInventory: partnerScope.inventory,
                listingWantedInventory: partnerWishesForCandidate + availableViewerInventory,
                tagsByInventoryID: tagsByInventoryID,
                candidate: candidate,
                includesCash: true
            )
            conditionSignalsByItemID[candidate.id] = conditionSignals(
                candidate: candidate,
                partnerUser: partnerScope.usersByID[candidate.userId],
                partnerActivityWindows: partnerScope.activityWindowsByUser[candidate.userId, default: []],
                viewerActivityWindows: composition.viewerActivityWindows,
                viewerUser: viewerUser,
                viewerAllowsMail: viewerAllowsMail,
                viewerAllowsLocal: viewerAllowsLocal,
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
                ownerHasMegrumPlus: composition.megrumPlusUserIDs.contains(candidate.userId)
            )

            if satisfiesViewerWish && partnerWantsViewerGoods {
                matched.append(candidateItem)
            } else if satisfiesViewerWish || partnerWantsViewerGoods {
                possible.append(candidateItem)
            }
        }

        for viewerItem in viewerInventory where HomeCandidateRowMapper.isMarketAvailable(viewerItem) {
            let matchingPartnerWishes = partnerScope.wishes.filter { partnerWish in
                wishRow(partnerWish, matches: viewerItem)
            }
            let wishMatchedPartnerUserIDs = orderedUnique(matchingPartnerWishes.map(\.userId))
            let matchingPartnerListings = partnerScope.listings.filter { listing in
                HomeCandidateListingMatchPolicy.listingWantsViewerGoods(
                    listing: listing,
                    options: listingOptionsByListingID[listing.id, default: []],
                    viewerInventory: [viewerItem]
                )
            }
            let matchingPartnerListingOptions = matchingPartnerListings.flatMap { listing in
                listingOptionsByListingID[listing.id, default: []].filter { option in
                    HomeCandidateListingMatchPolicy.optionWantsViewerGoods(option, viewerItem: viewerItem)
                }
            }
            let orderedPartnerIDs = orderedUnique(matchingPartnerWishes.map(\.userId) + matchingPartnerListings.map(\.userId))
            let paymentSignals = HomeCandidatePaymentPolicy.signals(
                viewerMethods: viewerUser?.paymentMethods,
                partnerMethodsList: orderedPartnerIDs.map { partnerScope.usersByID[$0]?.paymentMethods }
            )
            let partnerAllowsMail = matchingPartnerWishes.contains { exchangeAllowsMail($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsMail($0.exchangeType) }
            let partnerAllowsLocal = matchingPartnerWishes.contains { exchangeAllowsLocal($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsLocal($0.exchangeType) }
            let partnerLocalPrefectureNames = orderedPartnerIDs.compactMap { partnerID in
                partnerScope.usersByID[partnerID]?.primaryArea
            }
            let partnerLocalPrefectures = Set(
                partnerLocalPrefectureNames.compactMap(HomeCandidateComposer.normalizedArea)
            )
            let partnerLocalDateKeys = HomeCandidateComposer.localDateKeys(
                from: orderedPartnerIDs.flatMap { partnerID in
                    partnerScope.activityWindowsByUser[partnerID, default: []]
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
                prefecturesMatch(viewerUser?.primaryArea, partnerScope.usersByID[partnerID]?.primaryArea)
            }
            let individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
                listings: matchingPartnerListings,
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: [viewerItem],
                listingInventory: partnerScope.inventory,
                listingWantedInventory: partnerScope.wishes + [viewerItem],
                tagsByInventoryID: tagsByInventoryID
            )

            conditionSignalsByItemID[viewerItem.id] = HomeCandidateConditionSignals(
                goods: HomeGoodsConditionSignals(
                    hasIndividualListingHit: !matchingPartnerListings.isEmpty,
                    hasWishHit: !matchingPartnerWishes.isEmpty
                ),
                exchange: HomeExchangeConditionSignals(
                    postalAcceptedByBoth: exchangeAllowsMail(viewerItem.exchangeType) && partnerAllowsMail,
                    localExchangeSelected: exchangeAllowsLocal(viewerItem.exchangeType) && partnerAllowsLocal,
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
                    tagsByInventoryID: tagsByInventoryID
                )
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

    private static func viewerInterests(
        viewerWishes: [SupabaseHomeGoodsRow],
        viewerOshiSelections: [UserOshiSelection]
    ) -> [HomeCandidateViewerInterest] {
        guard viewerWishes.isEmpty else {
            return viewerWishes.map(HomeCandidateViewerInterest.wish)
        }
        return HomeCandidateViewerInterest.oshiSelections(viewerOshiSelections)
    }
}
