import Foundation
import MegrumCore
import SwiftUI

enum MatchRelationSwipeDirection {
    case previous
    case next

    var step: Int {
        switch self {
        case .previous:
            -1
        case .next:
            1
        }
    }
}

enum MatchRelationSwipeResolver {
    static let minimumHorizontalDistance: CGFloat = 8
    static let horizontalPriorityRatio: CGFloat = 1.08
    static let edgeResistanceRatio: CGFloat = 0.22

    static func direction(for translation: CGSize) -> MatchRelationSwipeDirection? {
        guard isHorizontalSwipe(translation) else {
            return nil
        }
        return translation.width < 0 ? .next : .previous
    }

    static func presentationOffset(
        translation: CGSize,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> CGFloat? {
        guard direction(for: translation) != nil else {
            return nil
        }
        let rawOffset = hasAdjacentTarget ? translation.width : translation.width * edgeResistanceRatio
        return max(-screenWidth, min(screenWidth, rawOffset))
    }

    static func shouldSwitchTarget(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> Bool {
        guard hasAdjacentTarget, direction(for: translation) != nil else {
            return false
        }
        let absX = abs(translation.width)
        let fastEnough = abs(predictedEndTranslationWidth) >= absX + 32 && absX >= 42
        return absX >= threshold(screenWidth: screenWidth) || fastEnough
    }

    static func threshold(screenWidth: CGFloat) -> CGFloat {
        min(118, max(72, screenWidth * 0.24))
    }

    private static func isHorizontalSwipe(_ translation: CGSize) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        return absX > minimumHorizontalDistance && absX > absY * horizontalPriorityRatio
    }
}

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

    static func initialCandidateSelection(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> [UUID: Set<UUID>] {
        var selection: [UUID: Set<UUID>] = [:]

        for detail in details {
            let highlightedHave = detail.haves.contains { $0.item.id == highlightedItemID }
            for option in detail.options where !option.option.isCashOffer {
                if highlightedHave, selection[detail.id, default: []].isEmpty {
                    let defaults = defaultCandidateIDs(for: option)
                    if !defaults.isEmpty {
                        selection[detail.id] = Set(defaults)
                        continue
                    }
                }

                for wish in option.wishes {
                    if wish.candidates.contains(where: { $0.item.id == highlightedItemID }) {
                        selection[detail.id, default: []].insert(highlightedItemID)
                    }
                }
            }
        }

        return selection
    }

    static func initialHaveSelection(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> [UUID: Set<UUID>] {
        var selection: [UUID: Set<UUID>] = [:]

        for detail in details where detail.listing.haveLogic == .one && detail.haves.count >= 2 {
            let highlighted = detail.haves.first { $0.item.id == highlightedItemID }
            let first = highlighted ?? detail.haves.first(where: \.matched) ?? detail.haves.first
            if let first {
                selection[detail.id] = [first.item.id]
            }
        }

        return selection
    }

    static func defaultPopupTarget(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> MatchRelationWishPopupTarget? {
        for detail in details {
            for option in detail.options where !option.option.isCashOffer {
                for wish in option.wishes where !wish.candidates.isEmpty {
                    guard wish.candidates.contains(where: { $0.item.id == highlightedItemID }),
                          let fallbackHave = defaultFallbackHave(for: detail, highlightedItemID: highlightedItemID) else {
                        continue
                    }
                    return MatchRelationWishPopupTarget(
                        listingID: detail.id,
                        viewpoint: detail.isMyListing ? .mine : .partner,
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        fallbackHave: fallbackHave
                    )
                }
            }
        }

        for detail in details {
            for option in detail.options where !option.option.isCashOffer {
                if let wish = option.wishes.first(where: { !$0.candidates.isEmpty }),
                   let fallbackHave = defaultFallbackHave(for: detail, highlightedItemID: highlightedItemID) {
                    return MatchRelationWishPopupTarget(
                        listingID: detail.id,
                        viewpoint: detail.isMyListing ? .mine : .partner,
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        fallbackHave: fallbackHave
                    )
                }
            }
        }

        return nil
    }

    static func defaultFallbackHave(
        for detail: MatchRelationListingDetail,
        highlightedItemID: UUID
    ) -> MatchRelationHave? {
        detail.haves.first { $0.item.id == highlightedItemID }
            ?? detail.haves.first(where: \.matched)
            ?? detail.haves.first
    }

    static func selectedCandidates(
        for wish: MatchRelationWish,
        selectedCandidateIDs: Set<UUID>
    ) -> [MatchRelationCandidate] {
        wish.candidates.filter { selectedCandidateIDs.contains($0.item.id) }
    }

    static func hasSelectedCandidate(
        for wish: MatchRelationWish,
        selectedCandidateIDs: Set<UUID>
    ) -> Bool {
        !selectedCandidates(for: wish, selectedCandidateIDs: selectedCandidateIDs).isEmpty
    }

    static func popupTarget(
        listingID: UUID,
        viewpoint: MatchRelationViewpoint,
        option: MatchRelationOption,
        wish: MatchRelationWish,
        fallbackHave: MatchRelationHave
    ) -> MatchRelationWishPopupTarget {
        MatchRelationWishPopupTarget(
            listingID: listingID,
            viewpoint: viewpoint,
            wish: wish,
            exchangeType: option.option.exchangeType,
            fallbackHave: fallbackHave
        )
    }

    static func aggregateSelection(
        details: [MatchRelationListingDetail],
        selectedCandidateIDsByListingID: [UUID: Set<UUID>],
        selectedHaveIDsByListingID: [UUID: Set<UUID>]
    ) -> MatchRelationAggregate {
        var senderItems: [GoodsItem] = []
        var receiverItems: [GoodsItem] = []
        var senderIDs: Set<UUID> = []
        var receiverIDs: Set<UUID> = []
        var referencedListingIDs: [UUID] = []

        func add(_ item: GoodsItem, to items: inout [GoodsItem], ids: inout Set<UUID>) {
            guard ids.insert(item.id).inserted else {
                return
            }
            items.append(item)
        }

        for detail in details {
            let selectedCandidateIDs = selectedCandidateIDsByListingID[detail.id] ?? []
            guard !selectedCandidateIDs.isEmpty else {
                continue
            }

            var seenCandidateIDs: Set<UUID> = []
            let selectedCandidates = detail.options
                .flatMap(\.wishes)
                .flatMap(\.candidates)
                .compactMap { candidate -> GoodsItem? in
                    guard selectedCandidateIDs.contains(candidate.item.id),
                          seenCandidateIDs.insert(candidate.item.id).inserted else {
                        return nil
                    }
                    return candidate.item
                }

            let selectedHaves: [MatchRelationHave]
            if detail.listing.haveLogic == .one, detail.haves.count >= 2 {
                let selectedHaveIDs = selectedHaveIDsByListingID[detail.id] ?? []
                selectedHaves = detail.haves.filter { selectedHaveIDs.contains($0.item.id) }
            } else {
                selectedHaves = detail.haves
            }

            guard !selectedCandidates.isEmpty, !selectedHaves.isEmpty else {
                continue
            }

            referencedListingIDs.append(detail.id)

            if detail.isMyListing {
                for have in selectedHaves {
                    add(have.item, to: &senderItems, ids: &senderIDs)
                }
                for candidate in selectedCandidates {
                    add(candidate, to: &receiverItems, ids: &receiverIDs)
                }
            } else {
                for candidate in selectedCandidates {
                    add(candidate, to: &senderItems, ids: &senderIDs)
                }
                for have in selectedHaves {
                    add(have.item, to: &receiverItems, ids: &receiverIDs)
                }
            }
        }

        return MatchRelationAggregate(
            senderItems: senderItems,
            receiverItems: receiverItems,
            senderIDs: Array(senderIDs),
            receiverIDs: Array(receiverIDs),
            referencedListingIDs: referencedListingIDs
        )
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

    private static func defaultCandidateIDs(for option: MatchRelationOption) -> [UUID] {
        let visibleWishes = option.wishes.filter { !$0.candidates.isEmpty }
        guard !visibleWishes.isEmpty else {
            return []
        }
        if option.option.logic == .all {
            return deduplicatedIDs(visibleWishes.compactMap { $0.candidates.first?.item.id })
        }
        if option.option.logic == .atLeast {
            return deduplicatedIDs(visibleWishes.compactMap { $0.candidates.first?.item.id })
                .prefix(max(1, option.option.minimumCount))
                .map { $0 }
        }
        return visibleWishes.first?.candidates.first.map { [$0.item.id] } ?? []
    }

    private static func deduplicatedCandidates(_ candidates: [MatchRelationCandidate]) -> [MatchRelationCandidate] {
        var seen: Set<UUID> = []
        return candidates.filter { seen.insert($0.item.id).inserted }
    }

    private static func deduplicatedIDs(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        return ids.filter { seen.insert($0).inserted }
    }
}
