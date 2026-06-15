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
        let viewerUser = composition.viewerUser
        let partnerWishesByUser = Dictionary(grouping: composition.partnerWishes, by: \.userId)
        let partnerListingsByUser = Dictionary(grouping: composition.partnerListings, by: \.userId)
        let listingOptionsByListingID = Dictionary(grouping: composition.listingWishOptions, by: \.listingId)
        let partnerUsersByID = Dictionary(uniqueKeysWithValues: composition.partnerUsers.map { ($0.id, $0) })
        let partnerActivityWindowsByUser = Dictionary(grouping: composition.partnerActivityWindows, by: \.userId)
        let availableViewerInventory = viewerInventory.filter(isMarketAvailable)
        let viewerAllowsMail = availableViewerInventory.contains { exchangeAllowsMail($0.exchangeType) }
        let viewerAllowsLocal = availableViewerInventory.contains { exchangeAllowsLocal($0.exchangeType) }

        var matched: [GoodsItem] = []
        var possible: [GoodsItem] = []
        var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

        for candidate in sortedCandidates(composition.partnerInventory) where isMarketAvailable(candidate) {
            let candidateItem = makeGoodsItem(
                from: candidate,
                tags: tagsByInventoryID[candidate.id] ?? [],
                ownerPrefecture: partnerUsersByID[candidate.userId]?.primaryArea,
                ownerPaymentMethods: partnerUsersByID[candidate.userId]?.paymentMethods ?? [],
                ownerPaymentNote: partnerUsersByID[candidate.userId]?.paymentNote
            )
            let matchingViewerWishes = viewerWishes.filter { wish in
                wishRow(wish, matches: candidate)
            }
            let satisfiesViewerWish = !matchingViewerWishes.isEmpty
            let tagMatchCount = tagMatchCount(
                itemID: candidate.id,
                matchingRows: matchingViewerWishes,
                tagsByInventoryID: tagsByInventoryID
            )
            let partnerWishHitCount = partnerWishesByUser[candidate.userId, default: []].filter { partnerWish in
                availableViewerInventory.contains { viewerItem in
                    wishRow(partnerWish, matches: viewerItem)
                }
            }.count
            let partnerListingHitCount = partnerListingsByUser[candidate.userId, default: []].filter { listing in
                listingIncludesCandidate(listing, candidate: candidate)
                    && listingHasSelectableWantedOption(
                        listing: listing,
                        options: listingOptionsByListingID[listing.id, default: []],
                        viewerInventory: availableViewerInventory,
                        includesCash: true
                    )
            }.count
            let partnerWishHit = partnerWishHitCount > 0
            let partnerListingHit = partnerListingHitCount > 0
            let partnerWantsViewerGoods = partnerWishHit || partnerListingHit
            let individualListingSelection = firstIndividualListingSelection(
                listings: partnerListingsByUser[candidate.userId, default: []],
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: availableViewerInventory,
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
                tagMatchCount: tagMatchCount,
                linkCounts: HomeCandidateLinkCounts(
                    wishCount: partnerWishHitCount,
                    listingCount: partnerListingHitCount
                ),
                individualListingSelection: individualListingSelection
            )

            if satisfiesViewerWish && partnerWantsViewerGoods {
                matched.append(candidateItem)
            } else if satisfiesViewerWish || partnerWantsViewerGoods {
                possible.append(candidateItem)
            }
        }

        for viewerItem in viewerInventory where isMarketAvailable(viewerItem) {
            let matchingPartnerWishes = composition.partnerWishes.filter { partnerWish in
                wishRow(partnerWish, matches: viewerItem)
            }
            let matchingPartnerListings = composition.partnerListings.filter { listing in
                listingWantsViewerGoods(
                    listing: listing,
                    options: listingOptionsByListingID[listing.id, default: []],
                    viewerInventory: [viewerItem]
                )
            }
            let matchingPartnerListingOptions = matchingPartnerListings.flatMap { listing in
                listingOptionsByListingID[listing.id, default: []].filter { option in
                    optionWantsViewerGoods(option, viewerItem: viewerItem)
                }
            }
            let partnerIDs = Set(matchingPartnerWishes.map(\.userId) + matchingPartnerListings.map(\.userId))
            let paymentMatches = partnerIDs.contains { partnerID in
                paymentMethodsOverlap(viewerUser?.paymentMethods, partnerUsersByID[partnerID]?.paymentMethods)
            }
            let prefectureMatches = partnerIDs.contains { partnerID in
                prefecturesMatch(viewerUser?.primaryArea, partnerUsersByID[partnerID]?.primaryArea)
            }
            let partnerAllowsMail = matchingPartnerWishes.contains { exchangeAllowsMail($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsMail($0.exchangeType) }
            let partnerAllowsLocal = matchingPartnerWishes.contains { exchangeAllowsLocal($0.exchangeType) }
                || matchingPartnerListingOptions.contains { exchangeAllowsLocal($0.exchangeType) }
            let individualListingSelection = firstIndividualListingSelection(
                listings: matchingPartnerListings,
                optionsByListingID: listingOptionsByListingID,
                viewerInventory: [viewerItem]
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
                payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: paymentMatches),
                linkCounts: HomeCandidateLinkCounts(
                    wishCount: matchingPartnerWishes.count,
                    listingCount: matchingPartnerListings.count
                ),
                individualListingSelection: individualListingSelection,
                tagMatchCount: tagMatchCount(
                    itemID: viewerItem.id,
                    matchingRows: matchingPartnerWishes,
                    tagsByInventoryID: tagsByInventoryID
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
        listingHasSelectableWantedOption(
            listing: listing,
            options: options,
            viewerInventory: viewerInventory,
            includesCash: false
        )
    }

    private static func listingHasSelectableWantedOption(
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

    private static func optionWantsViewerGoods(
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
        return fieldMatches(option.wishGroupId, viewerItem.groupId)
            && fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
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
        viewerUser: SupabaseHomeUserRow?,
        viewerAllowsMail: Bool,
        viewerAllowsLocal: Bool,
        hasIndividualListingHit: Bool,
        hasWishHit: Bool,
        matchesViewerWish: Bool,
        tagMatchCount: Int,
        linkCounts: HomeCandidateLinkCounts,
        individualListingSelection: HomeIndividualListingSelectionContext?
    ) -> HomeCandidateConditionSignals {
        let candidateAllowsMail = exchangeAllowsMail(candidate.exchangeType)
        let candidateAllowsLocal = exchangeAllowsLocal(candidate.exchangeType)
        let hasDateOverlap = activityWindowsOverlap(viewerActivityWindows, partnerActivityWindows)
        let hasLocalPlaceHint = prefecturesMatch(viewerUser?.primaryArea, partnerUser?.primaryArea)
        let hasCompatiblePaymentMethod = paymentMethodsOverlap(viewerUser?.paymentMethods, partnerUser?.paymentMethods)

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
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: hasCompatiblePaymentMethod),
            linkCounts: linkCounts,
            individualListingSelection: individualListingSelection,
            matchesViewerWish: matchesViewerWish,
            tagMatchCount: tagMatchCount
        )
    }

    private static func firstIndividualListingSelection(
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
                wantedOptions: wantedOptions
            )
        }
        return nil
    }

    private static func wantedOption(
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

        let kind: HomeIndividualListingWantedOption.Kind = option.wishIds.isEmpty ? .condition : .goods
        return HomeIndividualListingWantedOption(
            id: option.id,
            listingID: option.listingId,
            position: option.position,
            title: wantedOptionTitle(option: option, matchingItems: matchingItems),
            subtitle: wantedOptionSubtitle(option: option, matchingCount: matchingItems.count),
            logic: logic,
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
            return "\(option.wishIds.count)点から選択"
        }
        if option.wishGroupId != nil || option.wishGoodsTypeId != nil {
            return "\(matchingCount)件の候補"
        }
        return nil
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

    private static func tagMatchCount(
        itemID: UUID,
        matchingRows: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> Int {
        let itemTags = normalizedTagSet(tagsByInventoryID[itemID] ?? [])
        guard !itemTags.isEmpty else {
            return 0
        }
        let matchingTags = matchingRows.reduce(into: Set<String>()) { result, row in
            result.formUnion(normalizedTagSet(tagsByInventoryID[row.id] ?? []))
        }
        return itemTags.intersection(matchingTags).count
    }

    private static func normalizedTagSet(_ tags: [SupabaseHomeInventoryTagRow]) -> Set<String> {
        Set(tags.compactMap { tag in
            tag.label
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { value in
                    let withoutHash = value.hasPrefix("#") ? String(value.dropFirst()) : value
                    let normalized = withoutHash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return normalized.isEmpty ? nil : normalized
                }
        })
    }

    private static func paymentMethodsOverlap(_ lhs: [String]?, _ rhs: [String]?) -> Bool {
        let lhsMethods = paymentMethodSet(lhs)
        let rhsMethods = paymentMethodSet(rhs)
        return !lhsMethods.isDisjoint(with: rhsMethods)
    }

    private static func paymentMethodSet(_ methods: [String]?) -> Set<String> {
        let supported: Set<String> = ["bank_transfer", "paypay", "cash_exchange"]
        return Set((methods ?? []).map { $0.lowercased() }).intersection(supported)
    }

    private static func prefecturesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalizedArea(lhs),
              let rhs = normalizedArea(rhs)
        else {
            return false
        }
        return lhs == rhs
    }

    private static func normalizedArea(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private static func isMarketAvailable(_ row: SupabaseHomeGoodsRow) -> Bool {
        row.marketAvailableQuantity > 0
    }

    private static func makeGoodsItem(
        from row: SupabaseHomeGoodsRow,
        tags: [SupabaseHomeInventoryTagRow],
        ownerPrefecture: String?,
        ownerPaymentMethods: [String] = [],
        ownerPaymentNote: String? = nil
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
            quantity: max(1, row.marketAvailableQuantity),
            exchangeMethod: ExchangeMethod(exchangeTypeValue: row.exchangeType),
            ownerPrefecture: ownerPrefecture,
            ownerPaymentMethods: paymentMethods(ownerPaymentMethods),
            ownerPaymentNote: ownerPaymentNote
        )
    }

    private static func paymentMethods(_ values: [String]) -> [UserPaymentMethod] {
        let normalizedValues = Set(values.map { $0.lowercased() })
        return UserPaymentMethod.allCases.filter { method in
            normalizedValues.contains(method.rawValue)
        }
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

private extension SupabaseHomeGoodsRow {
    var marketAvailableQuantity: Int {
        if let marketAvailableQty {
            return max(0, marketAvailableQty)
        }
        return max(0, (quantity ?? 1) - (lockedQty ?? 0))
    }
}
