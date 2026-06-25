import Foundation
import MegrumCore

extension HomeDiscoveryCandidateFactory {
    static func conditionSignalsByGoodsID(
        for goods: [HomeMockGoods],
        selectedItemID: UUID,
        selectedSignals: HomeCandidateConditionSignals,
        source: HomeDiscoveryCandidateSource,
        index: Int,
        explicitSignals: [UUID: HomeCandidateConditionSignals]
    ) -> [UUID: HomeCandidateConditionSignals] {
        Dictionary(
            uniqueKeysWithValues: goods.enumerated().map { offset, goods in
                (
                    goods.id,
                    explicitSignals[goods.id]
                        ?? (goods.id == selectedItemID
                            ? selectedSignals
                            : fallbackSignals(for: source, index: index + offset))
                )
            }
        )
    }

    static func fallbackSignals(
        for source: HomeDiscoveryCandidateSource,
        index: Int
    ) -> HomeCandidateConditionSignals {
        switch source {
        case .userTag:
            return HomeCandidateConditionSignalDefaults.matched(index: index)
        case .user, .haves:
            return HomeCandidateConditionSignalDefaults.possible(index: index)
        }
    }

    static func sheet(
        for source: HomeDiscoveryCandidateSource,
        signals: HomeCandidateConditionSignals,
        selectedGoods: HomeMockGoods?
    ) -> HomeDiscoverySheet {
        guard source != .haves else {
            let offeredGoods = selectedGoods ?? HomeDiscoveryFixtures.selectedYellow
            return .havesLookup(
                HomeHavesLookupPayload(
                    offeredGoods: offeredGoods,
                    offeredSignals: signals,
                    tagMatchedCandidates: [],
                    memberMatchedCandidates: []
                )
            )
        }
        let fallbackGoods = selectedGoods ?? HomeDiscoveryFixtures.selectedYellow
        let payload = HomeDiscoverySheetPayload(goods: fallbackGoods, signals: signals)
        return HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) == .direct ? .goodsHit(payload) : .wishHit(payload)
    }

    static func title(for item: GoodsItem, source: HomeDiscoveryCandidateSource, goodsTypes: [GoodsType]) -> String {
        switch source {
        case .userTag:
            return memberTagTitle(from: item, goodsTypes: goodsTypes)
        case .haves:
            return item.title
        case .user:
            return masterDisplayName(for: item)
        }
    }

    static func memberTagTitle(from item: GoodsItem, goodsTypes: [GoodsType]) -> String {
        let memberName = masterDisplayName(for: item)
        if let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first {
            return HomeDiscoveryTitleParser.joinedMemberTagTitle(member: memberName, tag: tag)
        }
        return memberName
    }

    static func goodsStack(
        for item: GoodsItem,
        in items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        index: Int,
        goodsTypes: [GoodsType]
    ) -> [HomeMockGoods] {
        if source == .userTag {
            return items.enumerated().map { offset, item in
                HomeMockGoods.from(item: item, index: index + offset, goodsTypes: goodsTypes)
            }
        }

        var stack = [HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes)]
        let neighbors = items
            .filter { $0.id != item.id }
            .prefix(2)
            .enumerated()
            .map { offset, neighbor in
                HomeMockGoods.from(item: neighbor, index: index + offset + 1, goodsTypes: goodsTypes)
            }
        stack.append(contentsOf: neighbors)

        if source == .user {
            return stack
        }

        let fallback = [
            HomeDiscoveryFixtures.sanaBadge,
            HomeDiscoveryFixtures.sanaStand,
            HomeDiscoveryFixtures.sanaKeychain
        ]
        for goods in fallback where stack.count < 3 {
            stack.append(goods)
        }
        return stack
    }
}
