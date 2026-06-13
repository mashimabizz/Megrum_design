import Foundation
import MegrumCore
import MegrumData

public struct HomeCandidateSections: Equatable, Sendable {
    public var matchedItems: [GoodsItem]
    public var possibleItems: [GoodsItem]
    public var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]

    public init(
        matchedItems: [GoodsItem] = [],
        possibleItems: [GoodsItem] = [],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    ) {
        self.matchedItems = matchedItems
        self.possibleItems = possibleItems
        self.conditionSignalsByItemID = conditionSignalsByItemID
    }

    public var isEmpty: Bool {
        matchedItems.isEmpty && possibleItems.isEmpty
    }

    func resolvedWithFallbackInventory(_ fallbackInventory: [GoodsItem]) -> HomeCandidateSections {
        guard isEmpty else {
            return self
        }

        let matchedItems = fallbackInventory
        let possibleItems = Array(fallbackInventory.reversed())
        return HomeCandidateSections(
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: HomeCandidateConditionSignalDefaults.previewSignals(
                matchedItems: matchedItems,
                possibleItems: possibleItems
            )
        )
    }
}

enum HomeCandidateComposer {
    static func sections(from composition: SupabaseHomeComposition) -> HomeCandidateSections {
        let tagsByInventoryID = Dictionary(grouping: composition.inventoryTags, by: \.inventoryId)
        let viewerInventory = composition.viewerInventory
        let viewerWishes = composition.viewerWishes
        let partnerWishesByUser = Dictionary(grouping: composition.partnerWishes, by: \.userId)
        let partnerListingsByUser = Dictionary(grouping: composition.partnerListings, by: \.userId)
        let listingOptionsByListingID = Dictionary(grouping: composition.listingWishOptions, by: \.listingId)
        let partnerUsersByID = Dictionary(uniqueKeysWithValues: composition.partnerUsers.map { ($0.id, $0) })
        let partnerActivityWindowsByUser = Dictionary(grouping: composition.partnerActivityWindows, by: \.userId)
        let viewerAllowsMail = viewerInventory.contains { exchangeAllowsMail($0.exchangeType) }
        let viewerAllowsLocal = viewerInventory.contains { exchangeAllowsLocal($0.exchangeType) }

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []
        var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

        for candidate in sortedCandidates(composition.partnerInventory) {
            let candidateItem = makeGoodsItem(
                from: candidate,
                tags: tagsByInventoryID[candidate.id] ?? [],
                ownerPrefecture: partnerUsersByID[candidate.userId]?.primaryArea
            )
            let satisfiesViewerWish = viewerWishes.contains { wish in
                wishRow(wish, matches: candidate)
            }
            let partnerWishHitCount = partnerWishesByUser[candidate.userId, default: []].filter { partnerWish in
                viewerInventory.contains { viewerItem in
                    wishRow(partnerWish, matches: viewerItem)
                }
            }.count
            let partnerListingHitCount = partnerListingsByUser[candidate.userId, default: []].filter { listing in
                listingIncludesCandidate(listing, candidate: candidate)
                    && listingWantsViewerGoods(
                        listing: listing,
                        options: listingOptionsByListingID[listing.id, default: []],
                        viewerInventory: viewerInventory
                    )
            }.count
            let partnerWishHit = partnerWishHitCount > 0
            let partnerListingHit = partnerListingHitCount > 0
            let partnerWantsViewerGoods = partnerWishHit || partnerListingHit
            conditionSignalsByItemID[candidate.id] = conditionSignals(
                candidate: candidate,
                partnerUser: partnerUsersByID[candidate.userId],
                partnerActivityWindows: partnerActivityWindowsByUser[candidate.userId, default: []],
                viewerActivityWindows: composition.viewerActivityWindows,
                viewerAllowsMail: viewerAllowsMail,
                viewerAllowsLocal: viewerAllowsLocal,
                hasIndividualListingHit: partnerListingHit,
                hasWishHit: partnerWishHit,
                linkCounts: HomeCandidateLinkCounts(
                    wishCount: partnerWishHitCount,
                    listingCount: partnerListingHitCount
                )
            )

            if satisfiesViewerWish && partnerWantsViewerGoods {
                matched.append(candidateItem)
            } else if satisfiesViewerWish || partnerWantsViewerGoods {
                possible.append(candidateItem)
            }
        }

        for viewerItem in viewerInventory {
            let wishCount = composition.partnerWishes.filter { partnerWish in
                wishRow(partnerWish, matches: viewerItem)
            }.count
            let listingCount = composition.partnerListings.filter { listing in
                listingWantsViewerGoods(
                    listing: listing,
                    options: listingOptionsByListingID[listing.id, default: []],
                    viewerInventory: [viewerItem]
                )
            }.count

            conditionSignalsByItemID[viewerItem.id] = HomeCandidateConditionSignals(
                goods: HomeGoodsConditionSignals(
                    hasIndividualListingHit: listingCount > 0,
                    hasWishHit: wishCount > 0
                ),
                exchange: HomeExchangeConditionSignals(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: false,
                    prefectureMatches: false,
                    dateMatches: false
                ),
                linkCounts: HomeCandidateLinkCounts(
                    wishCount: wishCount,
                    listingCount: listingCount
                )
            )
        }

        return HomeCandidateSections(
            matchedItems: deduplicated(matched),
            possibleItems: deduplicated(possible),
            conditionSignalsByItemID: conditionSignalsByItemID
        )
    }

    private static func sortedCandidates(_ rows: [SupabaseHomeGoodsRow]) -> [SupabaseHomeGoodsRow] {
        rows.sorted { lhs, rhs in
            switch (lhs.updatedAt, rhs.updatedAt) {
            case let (lhsDate?, rhsDate?):
                lhsDate > rhsDate
            case (_?, nil):
                true
            case (nil, _?):
                false
            case (nil, nil):
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }
    }

    private static func wishRow(_ wish: SupabaseHomeGoodsRow, matches item: SupabaseHomeGoodsRow) -> Bool {
        fieldMatches(wish.groupId, item.groupId)
            && fieldMatches(wish.characterId ?? wish.characterRequestId, item.characterId ?? item.characterRequestId)
            && fieldMatches(wish.goodsTypeId, item.goodsTypeId)
    }

    private static func listingWantsViewerGoods(
        listing: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow]
    ) -> Bool {
        return options.contains { option in
            viewerInventory.contains { viewerItem in
                option.wishIds.contains(viewerItem.id)
                    || fieldMatches(option.wishGroupId, viewerItem.groupId)
                    && fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
            }
        }
    }

    private static func listingIncludesCandidate(
        _ listing: SupabaseHomeListingRow,
        candidate: SupabaseHomeGoodsRow
    ) -> Bool {
        if listing.haveIds.contains(candidate.id) {
            return true
        }
        if fieldMatches(listing.haveGroupId, candidate.groupId),
           fieldMatches(listing.haveGoodsTypeId, candidate.goodsTypeId) {
            return true
        }
        return listing.haveIds.isEmpty && listing.haveGroupId == nil && listing.haveGoodsTypeId == nil
    }

    private static func conditionSignals(
        candidate: SupabaseHomeGoodsRow,
        partnerUser: SupabaseHomeUserRow?,
        partnerActivityWindows: [SupabaseHomeActivityWindowRow],
        viewerActivityWindows: [SupabaseHomeActivityWindowRow],
        viewerAllowsMail: Bool,
        viewerAllowsLocal: Bool,
        hasIndividualListingHit: Bool,
        hasWishHit: Bool,
        linkCounts: HomeCandidateLinkCounts
    ) -> HomeCandidateConditionSignals {
        let candidateAllowsMail = exchangeAllowsMail(candidate.exchangeType)
        let candidateAllowsLocal = exchangeAllowsLocal(candidate.exchangeType)
        let hasDateOverlap = activityWindowsOverlap(viewerActivityWindows, partnerActivityWindows)
        let hasLocalPlaceHint = partnerUser?.primaryArea?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || !partnerActivityWindows.isEmpty

        return HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: hasIndividualListingHit,
                hasWishHit: hasWishHit
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: candidateAllowsMail && viewerAllowsMail,
                localExchangeSelected: candidateAllowsLocal && viewerAllowsLocal,
                prefectureMatches: hasLocalPlaceHint,
                dateMatches: hasDateOverlap
            ),
            linkCounts: linkCounts
        )
    }

    private static func exchangeAllowsMail(_ value: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: value) else {
            return false
        }
        return method == .mail || method == .both
    }

    private static func exchangeAllowsLocal(_ value: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: value) else {
            return true
        }
        return method == .hand || method == .both
    }

    private static func activityWindowsOverlap(
        _ viewerWindows: [SupabaseHomeActivityWindowRow],
        _ partnerWindows: [SupabaseHomeActivityWindowRow]
    ) -> Bool {
        viewerWindows.contains { viewerWindow in
            partnerWindows.contains { partnerWindow in
                windowsOverlap(viewerWindow, partnerWindow)
            }
        }
    }

    private static func windowsOverlap(
        _ lhs: SupabaseHomeActivityWindowRow,
        _ rhs: SupabaseHomeActivityWindowRow
    ) -> Bool {
        lhs.startAt < rhs.endAt && rhs.startAt < lhs.endAt
    }

    private static func fieldMatches(_ expected: UUID?, _ actual: UUID?) -> Bool {
        guard let expected else {
            return true
        }
        return expected == actual
    }

    private static func makeGoodsItem(
        from row: SupabaseHomeGoodsRow,
        tags: [SupabaseHomeInventoryTagRow],
        ownerPrefecture: String?
    ) -> GoodsItem {
        GoodsItem(
            id: row.id,
            ownerID: row.userId,
            groupID: row.groupId,
            memberID: row.characterId ?? row.characterRequestId,
            goodsTypeID: row.goodsTypeId,
            title: row.title,
            imageURL: row.photoUrls.compactMap(URL.init(string:)).first,
            tags: tags.compactMap { tag in
                guard let label = tag.label?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !label.isEmpty
                else {
                    return nil
                }
                return GoodsTag(id: tag.tagId, name: label)
            },
            quantity: max(1, row.quantity ?? 1),
            exchangeMethod: ExchangeMethod(exchangeTypeValue: row.exchangeType),
            ownerPrefecture: ownerPrefecture
        )
    }

    private static func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
