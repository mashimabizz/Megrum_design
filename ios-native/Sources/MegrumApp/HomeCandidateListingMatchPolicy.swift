import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingMatchPolicy {
    static func listingWantsViewerGoods(
        listing: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow]
    ) -> Bool {
        listingHasSelectableWantedOption(
            listing: listing,
            options: options,
            viewerInventory: viewerInventory,
            includesCash: false
        )
    }

    static func listingHasSelectableWantedOption(
        listing _: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        includesCash: Bool
    ) -> Bool {
        options.contains { option in
            if includesCash && option.isCashOffer == true {
                return true
            }
            return viewerInventory.contains { viewerItem in
                optionWantsViewerGoods(option, viewerItem: viewerItem)
            }
        }
    }

    static func listingIncludesCandidate(
        _ listing: SupabaseHomeListingRow,
        candidate: SupabaseHomeGoodsRow
    ) -> Bool {
        if listing.haveIds.contains(candidate.id) {
            return true
        }
        if HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, candidate.groupId),
           HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, candidate.goodsTypeId) {
            return true
        }
        return listing.haveIds.isEmpty && listing.haveGroupId == nil && listing.haveGoodsTypeId == nil
    }

    static func firstSelection(
        listings: [SupabaseHomeListingRow],
        optionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        viewerInventory: [SupabaseHomeGoodsRow],
        candidate: SupabaseHomeGoodsRow? = nil,
        includesCash: Bool = false
    ) -> HomeIndividualListingSelectionContext? {
        for listing in listings {
            if let candidate, !listingIncludesCandidate(listing, candidate: candidate) {
                continue
            }

            let sortedOptions = optionsByListingID[listing.id, default: []]
                .sorted { lhs, rhs in
                    if lhs.position == rhs.position {
                        return lhs.id.uuidString < rhs.id.uuidString
                    }
                    return lhs.position < rhs.position
                }
            let wantedOptions = sortedOptions.compactMap { option in
                wantedOption(
                    from: option,
                    viewerInventory: viewerInventory,
                    includesCash: includesCash
                )
            }
            guard let firstOption = wantedOptions.first else {
                continue
            }

            return HomeIndividualListingSelectionContext(
                wantedLogic: firstOption.logic,
                offeredLogic: ListingLogic(rawValue: listing.haveLogic ?? "") ?? .all,
                wantedMinimumCount: firstOption.minimumCount,
                offeredMinimumCount: listing.haveMinCount ?? 1,
                wantedOptions: wantedOptions
            )
        }
        return nil
    }

    static func optionWantsViewerGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        viewerItem: SupabaseHomeGoodsRow
    ) -> Bool {
        guard option.isCashOffer != true else {
            return false
        }
        if option.wishIds.contains(viewerItem.id) {
            return true
        }
        guard option.wishGroupId != nil || option.wishGoodsTypeId != nil else {
            return false
        }
        return HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGroupId, viewerItem.groupId)
            && HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
    }

    static func wantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        let logic = ListingLogic(rawValue: option.logic ?? "") ?? .one
        if option.isCashOffer == true {
            guard includesCash else {
                return nil
            }
            return HomeIndividualListingWantedOption(
                id: option.id,
                listingID: option.listingId,
                position: option.position,
                title: TradeAmountFormatter.fixedPrice(amount: option.cashAmount),
                subtitle: "金額で受け取る条件",
                logic: logic,
                kind: .cash,
                cashAmount: option.cashAmount
            )
        }

        let matchingItems = viewerInventory.filter { viewerItem in
            optionWantsViewerGoods(option, viewerItem: viewerItem)
        }
        guard !matchingItems.isEmpty else {
            return nil
        }
        if logic == .atLeast, matchingItems.count < max(1, option.minCount ?? 1) {
            return nil
        }

        let kind: HomeIndividualListingWantedOption.Kind = option.wishIds.isEmpty ? .condition : .goods
        return HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: wantedOptionTitle(option: option, matchingItems: matchingItems),
            subtitle: wantedOptionSubtitle(option: option, matchingCount: matchingItems.count),
            logic: logic,
            minimumCount: option.minCount ?? 1,
            kind: kind,
            goodsIDs: option.wishIds,
            matchingGoodsIDs: matchingItems.map(\.id),
            groupID: option.wishGroupId,
            goodsTypeID: option.wishGoodsTypeId
        )
    }

    private static func wantedOptionTitle(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow]
    ) -> String {
        if !option.wishIds.isEmpty {
            if let exactItem = matchingItems.first(where: { option.wishIds.contains($0.id) }) {
                return exactItem.title
            }
            return matchingItems.first?.title ?? "グッズ指定"
        }
        if let first = matchingItems.first {
            return first.title
        }
        return "条件指定"
    }

    private static func wantedOptionSubtitle(
        option: SupabaseHomeListingWishOptionRow,
        matchingCount: Int
    ) -> String? {
        if option.wishIds.count > 1 {
            if ListingLogic(rawValue: option.logic ?? "") == .atLeast {
                return ListingLogic.minimumCountTitle(option.minCount ?? 1)
            }
            return "\(option.wishIds.count)点から選択"
        }
        if option.wishGroupId != nil || option.wishGoodsTypeId != nil {
            return "\(matchingCount)件の候補"
        }
        return nil
    }
}
