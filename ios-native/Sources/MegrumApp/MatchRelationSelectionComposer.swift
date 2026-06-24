import Foundation
import MegrumCore

extension MatchRelationComposer {
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

    private static func deduplicatedIDs(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        return ids.filter { seen.insert($0).inserted }
    }
}
