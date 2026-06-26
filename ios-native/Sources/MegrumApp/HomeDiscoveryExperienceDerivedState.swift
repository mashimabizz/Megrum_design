import Foundation
import MegrumCore

extension HomeDiscoveryExperience {
    var userTagCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { item in
                HomeDiscoveryMatchPolicy.isMemberTagMatchEligible(
                    item: item,
                    signals: displayConditionSignalsByItemID[item.id]
                )
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .userTag,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        return Array(candidates.prefix(4))
    }

    var userCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { item in
                HomeDiscoveryMatchPolicy.isMemberMatchEligible(
                    item: item,
                    signals: displayConditionSignalsByItemID[item.id]
                )
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .user,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        return Array(candidates.prefix(HomeDiscoveryCandidateFactory.memberCandidateDisplayLimit))
    }

    var havesCandidates: [HomeDiscoveryCandidate] {
        let inventoryViewerItems = ownItems(from: inventoryItems)
        let viewerItems = inventoryViewerItems.isEmpty ? ownItems(from: matchedItems + possibleItems) : inventoryViewerItems
        let sourceItems = viewerItems.isEmpty ? possibleItems : viewerItems
        let sortedSourceItems = sourceItems
            .filter { havesWishHitCount(for: $0) > 0 }
            .sorted(by: candidateSorter.areInHavesOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(sortedSourceItems.prefix(8)),
            source: .haves,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        let itemByID = sortedSourceItems.reduce(into: [UUID: GoodsItem]()) { result, item in
            result[item.id] = result[item.id] ?? item
        }
        let havesCandidates = candidates.compactMap { candidate in
            visibleHavesCandidate(candidate, sourceItem: itemByID[candidate.id])
        }
        return havesCandidates
    }

    var viewerOfferGoods: [HomeMockGoods] {
        ownItems(from: inventoryItems)
            .filter { $0.marketAvailableQuantity > 0 }
            .enumerated()
            .map { index, item in
                HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes)
            }
    }

    var mutualMatchCandidates: [HomeMutualMatchCandidate] {
        HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: mutualMatchCandidateData,
            viewerID: viewer?.id,
            inventoryItems: inventoryItems,
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
    }

    var viewerIndividualListingCount: Int {
        appState?.listings.filter { $0.status != .closed }.count ?? 0
    }

    var defaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
    }

    var displayConditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] {
        defaultExchangeSettings.applying(to: conditionSignalsByItemID)
    }

    private var candidateSorter: HomeDiscoveryCandidateSorter {
        HomeDiscoveryCandidateSorter(conditionSignalsByItemID: displayConditionSignalsByItemID)
    }

    private func partnerItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return deduplicated(items)
        }
        return deduplicated(items.filter { $0.ownerID != viewerID })
    }

    private func ownItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return []
        }
        return deduplicated(items.filter { $0.ownerID == viewerID })
    }

    private func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }

    private func visibleHavesCandidate(
        _ candidate: HomeDiscoveryCandidate,
        sourceItem: GoodsItem?
    ) -> HomeDiscoveryCandidate? {
        guard let sourceItem else {
            return nil
        }
        let payload = havesLookupPayload(for: sourceItem, baseCandidate: candidate)
        guard payload.hasAnyMatches else {
            return nil
        }
        var updated = candidate
        updated.sheet = .havesLookup(payload)
        return updated
    }

    private func havesLookupPayload(
        for offeredItem: GoodsItem,
        baseCandidate: HomeDiscoveryCandidate
    ) -> HomeHavesLookupPayload {
        let offeredGoods = baseCandidate.goods.first ?? HomeMockGoods.from(
            item: offeredItem,
            index: 0,
            goodsTypes: goodsTypes
        )
        let offeredSignals = displayConditionSignalsByItemID[offeredItem.id] ?? baseCandidate.signals
        let tagMatchedItems = havesTagMatchedItems(for: offeredItem)
        let tagMatchedIDs = Set(tagMatchedItems.map(\.id))
        let memberMatchedItems = havesMemberMatchedItems(for: offeredItem)
            .filter { !tagMatchedIDs.contains($0.id) }

        return HomeHavesLookupPayload(
            offeredGoods: offeredGoods,
            offeredSignals: offeredSignals,
            tagMatchedCandidates: havesMatchCandidates(
                from: tagMatchedItems,
                source: .userTag,
                preferredOfferGoodsID: offeredItem.id
            ),
            memberMatchedCandidates: havesMatchCandidates(
                from: memberMatchedItems,
                source: .user,
                preferredOfferGoodsID: offeredItem.id
            )
        )
    }

    private func havesTagMatchedItems(for offeredItem: GoodsItem) -> [GoodsItem] {
        let offeredTags = matchingTagSet(for: offeredItem)
        guard !offeredTags.isEmpty else {
            return []
        }
        return havesPartnerPool(for: offeredItem)
            .filter { !matchingTagSet(for: $0).isDisjoint(with: offeredTags) }
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesMemberMatchedItems(for offeredItem: GoodsItem) -> [GoodsItem] {
        havesPartnerPool(for: offeredItem)
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesPartnerPool(for offeredItem: GoodsItem) -> [GoodsItem] {
        let partnerUserIDs = Set(displayConditionSignalsByItemID[offeredItem.id]?.wishMatchedPartnerUserIDs ?? [])
        guard !partnerUserIDs.isEmpty else {
            return []
        }
        return partnerItems(from: matchedItems + possibleItems)
            .filter { $0.id != offeredItem.id }
            .filter { partnerUserIDs.contains($0.ownerID) }
    }

    private func havesMatchCandidates(
        from items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        preferredOfferGoodsID: UUID
    ) -> [HomeDiscoveryCandidate] {
        HomeDiscoveryCandidateFactory.candidates(
            from: Array(items.prefix(6)),
            source: source,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        .map { candidate in
            var updated = candidate
            updated.sheet = havesMatchSheet(for: candidate, preferredOfferGoodsID: preferredOfferGoodsID)
            return updated
        }
    }

    private func havesMatchSheet(
        for candidate: HomeDiscoveryCandidate,
        preferredOfferGoodsID: UUID
    ) -> HomeDiscoverySheet {
        let goods = candidate.goods.first ?? HomeDiscoveryFixtures.selectedYellow
        let signals = candidate.conditionSignals(for: goods)
        let payload = HomeDiscoverySheetPayload(
            goods: goods,
            signals: signals,
            preferredOfferGoodsID: preferredOfferGoodsID
        )
        return HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) == .direct
            ? .goodsHit(payload)
            : .wishHit(payload)
    }

    private func memberMatches(_ lhs: GoodsItem, _ rhs: GoodsItem) -> Bool {
        if let lhsMemberID = lhs.memberID,
           let rhsMemberID = rhs.memberID {
            return lhsMemberID == rhsMemberID
        }
        let lhsMemberName = normalizedMasterName(lhs.memberName)
        let rhsMemberName = normalizedMasterName(rhs.memberName)
        if !lhsMemberName.isEmpty, lhsMemberName == rhsMemberName {
            return true
        }
        if let lhsGroupID = lhs.groupID,
           let rhsGroupID = rhs.groupID {
            return lhsGroupID == rhsGroupID
        }
        return false
    }

    private func normalizedMasterName(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    private func matchingTagSet(for item: GoodsItem) -> Set<String> {
        Set(HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes))
    }

    private func havesWishHitCount(for item: GoodsItem) -> Int {
        displayConditionSignalsByItemID[item.id]?.linkCounts.wishCount ?? 0
    }
}
