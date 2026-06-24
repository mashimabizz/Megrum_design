import Foundation
import MegrumCore

enum MatchRelationComposer {
    static func selectableSenderGoods(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { item in
            guard item.kind == nil || item.kind == .inventory else {
                return false
            }
            switch item.status {
            case nil, .active, .reserved:
                return item.marketAvailableQuantity > 0
            case .keep, .traded, .archived:
                return false
            }
        }
    }

    static func deduplicatedGoods(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        return items.filter { seen.insert($0.id).inserted }
    }

    static func orderedIDs(_ selectedIDs: Set<UUID>, in items: [GoodsItem]) -> [UUID] {
        items.map(\.id).filter { selectedIDs.contains($0) }
    }

    static func fallbackSenderIDs(for target: GoodsItem, inventory: [GoodsItem]) -> [UUID] {
        let exact = inventory.filter { item in
            item.groupID == target.groupID
                && item.memberID == target.memberID
                && item.goodsTypeID == target.goodsTypeID
        }
        if let firstExact = exact.first {
            return [firstExact.id]
        }

        let sameGroup = inventory.filter { item in
            item.groupID == target.groupID
                && (target.goodsTypeID == nil || item.goodsTypeID == target.goodsTypeID)
        }
        if let firstSameGroup = sameGroup.first {
            return [firstSameGroup.id]
        }

        return inventory.first.map { [$0.id] } ?? []
    }

    static func buildRelationDetails(
        ownListings: [IndividualListing],
        partnerListings: [IndividualListing],
        senderGoods: [GoodsItem],
        partnerGoods: [GoodsItem],
        highlightedItemID: UUID
    ) -> [MatchRelationListingDetail] {
        let ownDetails = ownListings
            .filter { $0.status == .active }
            .compactMap { listing in
                detail(
                    for: listing,
                    isMyListing: true,
                    havesSource: senderGoods,
                    candidateSource: partnerGoods,
                    highlightedItemID: highlightedItemID
                )
            }

        let partnerDetails = partnerListings
            .filter { $0.status == .active }
            .compactMap { listing in
                detail(
                    for: listing,
                    isMyListing: false,
                    havesSource: partnerGoods,
                    candidateSource: senderGoods,
                    highlightedItemID: highlightedItemID
                )
            }

        return ownDetails + partnerDetails
    }

    static func relationSwipeItems(homeMatchedItems: [GoodsItem], currentTarget: GoodsItem) -> [GoodsItem] {
        let deduplicated = deduplicatedGoods(homeMatchedItems)
        guard !deduplicated.isEmpty else {
            return [currentTarget]
        }
        if deduplicated.contains(where: { $0.id == currentTarget.id }) {
            return deduplicated
        }
        return deduplicatedGoods([currentTarget] + deduplicated)
    }

    static func adjacentSwipeTarget(
        in items: [GoodsItem],
        currentID: UUID,
        direction: MatchRelationSwipeDirection
    ) -> GoodsItem? {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentID }) else {
            return nil
        }
        let nextIndex = currentIndex + direction.step
        guard items.indices.contains(nextIndex) else {
            return nil
        }
        return items[nextIndex]
    }

    static func itemsMatch(candidate: GoodsItem, wish: GoodsItem, fallbackGroupID: UUID?, fallbackGoodsTypeID: UUID?) -> Bool {
        let wishGroupID = wish.groupID ?? fallbackGroupID
        let wishGoodsTypeID = wish.goodsTypeID ?? fallbackGoodsTypeID

        let candidateGoodsTypeID = candidate.goodsTypeID
        if candidateGoodsTypeID != wishGoodsTypeID,
           candidateGoodsTypeID != nil || wishGoodsTypeID != nil {
            return false
        }
        if let candidateMemberID = candidate.memberID, let wishMemberID = wish.memberID {
            return candidateMemberID == wishMemberID
        }
        guard let candidateGroupID = candidate.groupID, let wishGroupID else {
            return candidate.id == wish.id
        }
        return candidateGroupID == wishGroupID
    }

    private static func detail(
        for listing: IndividualListing,
        isMyListing: Bool,
        havesSource: [GoodsItem],
        candidateSource: [GoodsItem],
        highlightedItemID: UUID
    ) -> MatchRelationListingDetail? {
        let havesByID = goodsByID(havesSource)
        let candidatesByID = goodsByID(candidateSource)
        let haves = listing.haves.compactMap { quantity -> MatchRelationHave? in
            guard let item = havesByID[quantity.itemID] else {
                return nil
            }
            return MatchRelationHave(
                item: item,
                quantity: quantity.quantity,
                matched: item.id == highlightedItemID || listing.options.contains { option in
                    option.wishes.contains { wish in
                        if let wishItem = candidatesByID[wish.itemID] {
                            return itemsMatch(
                                candidate: item,
                                wish: wishItem,
                                fallbackGroupID: option.wishGroupID,
                                fallbackGoodsTypeID: option.wishGoodsTypeID
                            )
                        }
                        return false
                    }
                }
            )
        }

        guard !haves.isEmpty else {
            return nil
        }

        let goodsByID = goodsByID(havesSource + candidateSource)
        let options = listing.options.map { option -> MatchRelationOption in
            let wishes = option.wishes.compactMap { wishQuantity -> MatchRelationWish? in
                let wishItem = goodsByID[wishQuantity.itemID] ?? GoodsItem(
                    id: wishQuantity.itemID,
                    ownerID: listing.ownerID,
                    groupID: option.wishGroupID,
                    goodsTypeID: option.wishGoodsTypeID,
                    title: "グッズ"
                )
                let candidates = candidateSource
                    .filter { candidate in
                        candidate.id == wishQuantity.itemID
                            || itemsMatch(
                                candidate: candidate,
                                wish: wishItem,
                                fallbackGroupID: option.wishGroupID,
                                fallbackGoodsTypeID: option.wishGoodsTypeID
                            )
                    }
                    .map { MatchRelationCandidate(item: $0, quantity: 1) }

                return MatchRelationWish(
                    item: wishItem,
                    quantity: wishQuantity.quantity,
                    candidates: deduplicatedCandidates(candidates)
                )
            }

            return MatchRelationOption(
                option: option,
                wishes: wishes,
                matched: option.isCashOffer || wishes.contains { !$0.candidates.isEmpty }
            )
        }

        let hasCandidateRelation = options.contains { option in
            !option.option.isCashOffer && option.wishes.contains { !$0.candidates.isEmpty }
        }
        let hasHighlightedHave = haves.contains { $0.item.id == highlightedItemID }
        guard hasCandidateRelation || hasHighlightedHave else {
            return nil
        }

        return MatchRelationListingDetail(
            listing: listing,
            isMyListing: isMyListing,
            haves: haves,
            options: options
        )
    }

    private static func goodsByID(_ items: [GoodsItem]) -> [UUID: GoodsItem] {
        items.reduce(into: [:]) { result, item in
            result[item.id] = result[item.id] ?? item
        }
    }

    private static func deduplicatedCandidates(_ candidates: [MatchRelationCandidate]) -> [MatchRelationCandidate] {
        var seen: Set<UUID> = []
        return candidates.filter { seen.insert($0.item.id).inserted }
    }
}
