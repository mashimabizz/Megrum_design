import Foundation
import MegrumCore

extension HomeDiscoveryExperience {
    var havesCandidates: [HomeDiscoveryCandidate] {
        // ガイドツアー中：実在庫やシグナル突き合わせに依存せず、サンプルを rail 表示する
        // （新規ユーザーは在庫0件でセクションが出ず、ハイライト対象が無くなるため）。
        if tutorialSampleActive {
            return tutorialSampleHavesCandidates
        }
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

    /// ツアーのサンプル「求められているグッズ」：需要シグナル（求/激求）が付くものを優先し、
    /// 足りなければ先頭から補完して rail に4〜6件並べる。タップはツアー中無効なので payload は不要。
    private var tutorialSampleHavesCandidates: [HomeDiscoveryCandidate] {
        var seenIDs = Set<UUID>()
        let pool = (matchedItems + possibleItems).filter { seenIDs.insert($0.id).inserted }
        let wanted = pool.filter { havesWishHitCount(for: $0) > 0 }
        let items = Array((wanted.isEmpty ? pool : wanted).prefix(6))
        return HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .haves,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        .map { candidate in
            // factory の .haves は空の havesLookup を sheet に入れ、件数表示が0件になる。
            // サンプルは linkCounts ベースの件数（N件）を出したいので sheet を差し替える。
            var updated = candidate
            if let goods = candidate.goods.first {
                updated.sheet = .goodsHit(HomeDiscoverySheetPayload(goods: goods, signals: candidate.signals))
            }
            return updated
        }
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
        let offeredTags = matchingSeriesSet(for: offeredItem)
        guard !offeredTags.isEmpty else {
            return []
        }
        return havesPartnerPool(for: offeredItem)
            .filter { !matchingSeriesSet(for: $0).isDisjoint(with: offeredTags) }
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

    private func matchingSeriesSet(for item: GoodsItem) -> Set<String> {
        Set(HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes))
    }

    private func havesWishHitCount(for item: GoodsItem) -> Int {
        displayConditionSignalsByItemID[item.id]?.linkCounts.wishCount ?? 0
    }
}
