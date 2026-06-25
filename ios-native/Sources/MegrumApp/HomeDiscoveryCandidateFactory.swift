import Foundation
import MegrumCore

enum HomeDiscoveryCandidateFactory {
    static let memberCandidateDisplayLimit = 10

    static func candidates(
        from items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        goodsTypes: [GoodsType] = [],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeDiscoveryCandidate] {
        if source == .userTag {
            return memberTagCandidates(
                from: items,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID
            )
        }

        if source == .user {
            return memberCandidates(
                from: items,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID
            )
        }

        return items.enumerated().map { index, item in
            candidate(
                from: item,
                in: items,
                source: source,
                index: index,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID
            )
        }
    }

    static func candidate(
        from item: GoodsItem,
        in items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        index: Int,
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals],
        titleOverride: String? = nil
    ) -> HomeDiscoveryCandidate {
        let signals = conditionSignalsByItemID[item.id] ?? fallbackSignals(for: source, index: index)
        let goods = goodsStack(for: item, in: items, source: source, index: index, goodsTypes: goodsTypes)
        return HomeDiscoveryCandidate(
            id: item.id,
            title: titleOverride ?? title(for: item, source: source, goodsTypes: goodsTypes),
            signals: signals,
            conditionSignalsByGoodsID: conditionSignalsByGoodsID(
                for: goods,
                selectedItemID: item.id,
                selectedSignals: signals,
                source: source,
                index: index,
                explicitSignals: conditionSignalsByItemID
            ),
            sheet: sheet(for: source, signals: signals, selectedGoods: goods.first),
            goods: goods
        )
    }
}
