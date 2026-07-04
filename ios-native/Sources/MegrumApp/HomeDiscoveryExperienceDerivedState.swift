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
        // 塊内に成立しやすいグッズを多く含むものが上（iter1226.272）。
        // 上位3件をセクション表示し、全件は「すべて見る」から。
        return HomeCandidateSummaryPolicy.sortedCandidates(candidates)
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
        return HomeCandidateSummaryPolicy.sortedCandidates(candidates)
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
