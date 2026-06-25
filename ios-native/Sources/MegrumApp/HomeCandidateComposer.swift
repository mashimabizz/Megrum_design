import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateComposer {
    static func sections(from composition: SupabaseHomeComposition) -> HomeCandidateSections {
        let tagsByInventoryID = Dictionary(grouping: composition.inventoryTags, by: \.inventoryId)
        let viewerInventory = composition.viewerInventory
        let viewerWishes = composition.viewerWishes
        let viewerUser = composition.viewerUser
        let listingOptionsByListingID = Dictionary(grouping: composition.listingWishOptions, by: \.listingId)
        let viewerIsTestAccount = composition.viewerUser.map(HomeCandidateRowMapper.isTestUser) ?? false
        let excludedTestPartnerUserIDs: Set<UUID> = viewerIsTestAccount
            ? []
            : Set(composition.partnerUsers.filter(HomeCandidateRowMapper.isTestUser).map(\.id))
        let visiblePartnerUsers = composition.partnerUsers.filter { !excludedTestPartnerUserIDs.contains($0.id) }
        let partnerInventory = viewerIsTestAccount
            ? composition.partnerInventory
            : composition.partnerInventory.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        let partnerWishes = viewerIsTestAccount
            ? composition.partnerWishes
            : composition.partnerWishes.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        let partnerListings = viewerIsTestAccount
            ? composition.partnerListings
            : composition.partnerListings.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        let partnerActivityWindows = viewerIsTestAccount
            ? composition.partnerActivityWindows
            : composition.partnerActivityWindows.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        let partnerWishesByUser = Dictionary(grouping: partnerWishes, by: \.userId)
        let partnerListingsByUser = Dictionary(grouping: partnerListings, by: \.userId)
        let partnerUsersByID = Dictionary(uniqueKeysWithValues: visiblePartnerUsers.map { ($0.id, $0) })
        let partnerActivityWindowsByUser = Dictionary(grouping: partnerActivityWindows, by: \.userId)
        let availableViewerInventory = viewerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let viewerAllowsMail = availableViewerInventory.contains { exchangeAllowsMail($0.exchangeType) }
        let viewerAllowsLocal = availableViewerInventory.contains { exchangeAllowsLocal($0.exchangeType) }
        let mutualMatchCandidates = mutualMatchCandidates(
            from: composition.filteredPartnerData(
                partnerInventory: partnerInventory,
                partnerWishes: partnerWishes,
                partnerUsers: visiblePartnerUsers,
                partnerListings: partnerListings,
                partnerActivityWindows: partnerActivityWindows
            ),
            tagsByInventoryID: tagsByInventoryID,
            listingOptionsByListingID: listingOptionsByListingID,
            partnerUsersByID: partnerUsersByID
        )

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []
        var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

        for candidate in sortedCandidates(partnerInventory) where HomeCandidateRowMapper.isMarketAvailable(candidate) {
            let candidateItem = HomeCandidateRowMapper.makeGoodsItem(
                from: candidate,
                tags: tagsByInventoryID[candidate.id] ?? [],
                ownerUser: partnerUsersByID[candidate.userId]
            )
            let matchingViewerWishes = viewerWishes.filter { wish in
                wishRow(wish, matches: candidate)
            }
            let satisfiesViewerWish = !matchingViewerWishes.isEmpty
            let satisfiesViewerWishCharacter = matchingViewerWishes.contains { wish in
                wishRowHasSameConfirmedCharacter(wish, candidate)
            }
            let tagMatchCount = HomeCandidateTagMatcher.count(
                itemID: candidate.id,
                matchingRows: matchingViewerWishes,
                tagsByInventoryID: tagsByInventoryID
            )
            let partnerWishesForCandidate = partnerWishesByUser[candidate.userId, default: []]
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
            let partnerListingHitCount = partnerListingsByUser[candidate.userId, default: []].filter { listing in
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
                listings: partnerListingsByUser[candidate.userId, default: []],
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: availableViewerInventory,
                listingInventory: partnerInventory,
                candidate: candidate,
                includesCash: true
            )
            conditionSignalsByItemID[candidate.id] = conditionSignals(
                candidate: candidate,
                partnerUser: partnerUsersByID[candidate.userId],
                partnerActivityWindows: partnerActivityWindowsByUser[candidate.userId, default: []],
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
                wishMatchedPartnerUserIDs: partnerWishHit ? [candidate.userId] : []
            )

            if satisfiesViewerWish && partnerWantsViewerGoods {
                matched.append(candidateItem)
            } else if satisfiesViewerWish || partnerWantsViewerGoods {
                possible.append(candidateItem)
            }
        }

        for viewerItem in viewerInventory where HomeCandidateRowMapper.isMarketAvailable(viewerItem) {
            let matchingPartnerWishes = partnerWishes.filter { partnerWish in
                wishRow(partnerWish, matches: viewerItem)
            }
            let wishMatchedPartnerUserIDs = orderedUnique(matchingPartnerWishes.map(\.userId))
            let matchingPartnerListings = partnerListings.filter { listing in
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
            let partnerIDs = Set(matchingPartnerWishes.map(\.userId) + matchingPartnerListings.map(\.userId))
            let paymentSignals = HomeCandidatePaymentPolicy.signals(
                viewerMethods: viewerUser?.paymentMethods,
                partnerMethodsList: partnerIDs.map { partnerUsersByID[$0]?.paymentMethods }
            )
            let prefectureMatches = partnerIDs.contains { partnerID in
                prefecturesMatch(viewerUser?.primaryArea, partnerUsersByID[partnerID]?.primaryArea)
            }
            let partnerAllowsMail = matchingPartnerWishes.contains { exchangeAllowsMail($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsMail($0.exchangeType) }
            let partnerAllowsLocal = matchingPartnerWishes.contains { exchangeAllowsLocal($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsLocal($0.exchangeType) }
            let individualListingSelection = HomeCandidateListingMatchPolicy.firstSelection(
                listings: matchingPartnerListings,
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: [viewerItem],
                listingInventory: partnerInventory
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
                    dateMatches: false
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
}

private extension SupabaseHomeComposition {
    func filteredPartnerData(
        partnerInventory: [SupabaseHomeGoodsRow],
        partnerWishes: [SupabaseHomeGoodsRow],
        partnerUsers: [SupabaseHomeUserRow],
        partnerListings: [SupabaseHomeListingRow],
        partnerActivityWindows: [SupabaseHomeActivityWindowRow]
    ) -> SupabaseHomeComposition {
        SupabaseHomeComposition(
            localMode: localMode,
            viewerUser: viewerUser,
            viewerInventory: viewerInventory,
            viewerWishes: viewerWishes,
            viewerListings: viewerListings,
            partnerInventory: partnerInventory,
            partnerWishes: partnerWishes,
            partnerUsers: partnerUsers,
            partnerListings: partnerListings,
            listingWishOptions: listingWishOptions,
            viewerActivityWindows: viewerActivityWindows,
            partnerActivityWindows: partnerActivityWindows,
            inventoryTags: inventoryTags,
            unreadNotificationIDs: unreadNotificationIDs
        )
    }
}
