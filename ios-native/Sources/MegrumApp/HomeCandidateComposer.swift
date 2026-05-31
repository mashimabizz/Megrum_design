import Foundation
import MegrumCore
import MegrumData

public struct HomeCandidateSections: Equatable, Sendable {
    public var matchedItems: [GoodsItem]
    public var possibleItems: [GoodsItem]

    public init(matchedItems: [GoodsItem] = [], possibleItems: [GoodsItem] = []) {
        self.matchedItems = matchedItems
        self.possibleItems = possibleItems
    }

    public var isEmpty: Bool {
        matchedItems.isEmpty && possibleItems.isEmpty
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

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []

        for candidate in sortedCandidates(composition.partnerInventory) {
            let candidateItem = makeGoodsItem(from: candidate, tags: tagsByInventoryID[candidate.id] ?? [])
            let satisfiesViewerWish = viewerWishes.contains { wish in
                wishRow(wish, matches: candidate)
            }
            let partnerWantsViewerGoods =
                partnerWishesByUser[candidate.userId, default: []].contains { partnerWish in
                    viewerInventory.contains { viewerItem in
                        wishRow(partnerWish, matches: viewerItem)
                    }
                }
                || partnerListingsByUser[candidate.userId, default: []].contains { listing in
                    listingWantsViewerGoods(
                        listing: listing,
                        options: listingOptionsByListingID[listing.id, default: []],
                        viewerInventory: viewerInventory
                    )
                }

            if satisfiesViewerWish && partnerWantsViewerGoods {
                matched.append(candidateItem)
            } else if satisfiesViewerWish || partnerWantsViewerGoods {
                possible.append(candidateItem)
            }
        }

        return HomeCandidateSections(
            matchedItems: deduplicated(matched),
            possibleItems: deduplicated(possible)
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
        if !listing.haveIds.isEmpty {
            return false
        }

        return options.contains { option in
            viewerInventory.contains { viewerItem in
                fieldMatches(option.wishGroupId, viewerItem.groupId)
                    && fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
            }
        }
    }

    private static func fieldMatches(_ expected: UUID?, _ actual: UUID?) -> Bool {
        guard let expected else {
            return true
        }
        return expected == actual
    }

    private static func makeGoodsItem(from row: SupabaseHomeGoodsRow, tags: [SupabaseHomeInventoryTagRow]) -> GoodsItem {
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
            quantity: max(1, row.quantity ?? 1)
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
