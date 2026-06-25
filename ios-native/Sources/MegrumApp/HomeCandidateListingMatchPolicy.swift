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
        listingInventory: [SupabaseHomeGoodsRow] = [],
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

            let wantedLogic = firstOption.logic
            let offeredLogic = ListingLogic(rawValue: listing.haveLogic ?? "") ?? .all
            let wantedMinimumCount = firstOption.minimumCount
            let offeredMinimumCount = listing.haveMinCount ?? 1
            let listingNote = IndividualListingNotePresentation.userMemo(from: listing.note)
            let detail = detailContext(
                listing: listing,
                wantedLogic: wantedLogic,
                offeredLogic: offeredLogic,
                wantedMinimumCount: wantedMinimumCount,
                offeredMinimumCount: offeredMinimumCount,
                wantedOptions: wantedOptions,
                listingInventory: listingInventory,
                candidate: candidate
            )

            return HomeIndividualListingSelectionContext(
                wantedLogic: wantedLogic,
                offeredLogic: offeredLogic,
                wantedMinimumCount: wantedMinimumCount,
                offeredMinimumCount: offeredMinimumCount,
                wantedOptions: wantedOptions,
                listingNote: listingNote,
                detail: detail
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

    private static func detailContext(
        listing: SupabaseHomeListingRow,
        wantedLogic: ListingLogic,
        offeredLogic: ListingLogic,
        wantedMinimumCount: Int,
        offeredMinimumCount: Int,
        wantedOptions: [HomeIndividualListingWantedOption],
        listingInventory: [SupabaseHomeGoodsRow],
        candidate: SupabaseHomeGoodsRow?
    ) -> HomeIndividualListingDetailContext {
        HomeIndividualListingDetailContext(
            listingID: listing.id,
            wantedLogic: wantedLogic,
            offeredLogic: offeredLogic,
            wantedMinimumCount: wantedMinimumCount,
            offeredMinimumCount: offeredMinimumCount,
            wantedOptions: wantedOptions,
            offeredItems: offeredItems(
                listing: listing,
                listingInventory: listingInventory,
                candidate: candidate
            ),
            offeredCashAmount: IndividualListingHaveCashSummary.extract(from: listing.note).summary?.amount
        )
    }

    private static func offeredItems(
        listing: SupabaseHomeListingRow,
        listingInventory: [SupabaseHomeGoodsRow],
        candidate: SupabaseHomeGoodsRow?
    ) -> [HomeIndividualListingOfferedItem] {
        let quantityByID = listingHaveQuantityByID(listing)
        let inventoryByID = Dictionary(uniqueKeysWithValues: listingInventory.map { ($0.id, $0) })
        var rows = listing.haveIds.compactMap { inventoryByID[$0] }
        if rows.isEmpty,
           let candidate,
           listingIncludesCandidate(listing, candidate: candidate) {
            rows = [candidate]
        }

        return rows.enumerated().map { _, row in
            HomeIndividualListingOfferedItem(
                id: row.id,
                title: row.title,
                imageURL: row.photoUrls.compactMap(URL.init(string:)).first,
                quantity: quantityByID[row.id] ?? 1
            )
        }
    }

    private static func listingHaveQuantityByID(_ listing: SupabaseHomeListingRow) -> [UUID: Int] {
        var quantityByID: [UUID: Int] = [:]
        for (index, id) in listing.haveIds.enumerated() {
            let quantity = listing.haveQtys.indices.contains(index) ? listing.haveQtys[index] : 1
            quantityByID[id] = max(1, quantity)
        }
        return quantityByID
    }
}
