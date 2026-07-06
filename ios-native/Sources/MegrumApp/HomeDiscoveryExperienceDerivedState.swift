import Foundation
import MegrumCore

extension HomeDiscoveryExperience {
    var userTagCandidates: [HomeDiscoveryCandidate] {
        // ガイドツアー中は推し一致フィルタを外し、サンプルを本物のレイアウトで見せる。
        if tutorialSampleActive {
            return tutorialSampleCandidates(from: matchedItems, source: .userTag)
        }
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
        // 需要基準の並び順：激求含む塊 > 求 > 定価 > 合致なし（iter1226.295）。
        // 上位3件をセクション表示し、全件は「すべて見る」から。
        return HomeCandidateDemandPolicy.sortedCandidates(candidates)
    }

    var userCandidates: [HomeDiscoveryCandidate] {
        if tutorialSampleActive {
            return tutorialSampleCandidates(from: possibleItems, source: .user)
        }
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
        return HomeCandidateDemandPolicy.sortedCandidates(candidates)
    }

    /// ツアーのサンプル候補：推し一致フィルタを通さず、他ユーザー所有分をそのまま候補化する。
    private func tutorialSampleCandidates(
        from items: [GoodsItem],
        source: HomeDiscoveryCandidateSource
    ) -> [HomeDiscoveryCandidate] {
        let partner = partnerItems(from: items)
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: partner,
            source: source,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        return HomeCandidateDemandPolicy.sortedCandidates(candidates)
    }

    /// 新着のグッズ（候補ゼロの時に見せる、他ユーザーの新着登録）。
    var recentCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: recentPartnerItems)
            .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
        return HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .user,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
    }

    /// 需要行のサムネイル用：自分のグッズID→画像URL。
    var viewerGoodsImageURLByID: [UUID: URL] {
        Dictionary(
            ownItems(from: inventoryItems).compactMap { item in
                item.imageURL.map { (item.id, $0) }
            },
            uniquingKeysWith: { first, _ in first }
        )
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
}
