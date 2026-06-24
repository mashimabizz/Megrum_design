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

    private struct MemberTagGroupKey: Hashable {
        var master: String
        var tag: String
        var fallbackID: UUID?
    }

    private struct MemberGroupKey: Hashable {
        var master: String
        var fallbackID: UUID?
    }

    private struct MemberTagDescriptor {
        var key: MemberTagGroupKey
        var title: String
    }

    private struct MemberDescriptor {
        var key: MemberGroupKey
        var title: String
    }

    private static func memberTagCandidates(
        from items: [GoodsItem],
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeDiscoveryCandidate] {
        var groupedItems: [MemberTagGroupKey: [GoodsItem]] = [:]
        var groupTitles: [MemberTagGroupKey: String] = [:]
        var orderedKeys: [MemberTagGroupKey] = []

        for item in items {
            let descriptor = memberTagDescriptor(for: item, goodsTypes: goodsTypes)
            if groupedItems[descriptor.key] == nil {
                orderedKeys.append(descriptor.key)
                groupTitles[descriptor.key] = descriptor.title
            }
            groupedItems[descriptor.key, default: []].append(item)
        }

        return orderedKeys.enumerated().compactMap { index, key in
            guard let items = groupedItems[key],
                  let firstItem = items.first
            else {
                return nil
            }
            return candidate(
                from: firstItem,
                in: items,
                source: .userTag,
                index: index,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID,
                titleOverride: groupTitles[key]
            )
        }
    }

    private static func memberCandidates(
        from items: [GoodsItem],
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeDiscoveryCandidate] {
        var groupedItems: [MemberGroupKey: [GoodsItem]] = [:]
        var groupTitles: [MemberGroupKey: String] = [:]
        var orderedKeys: [MemberGroupKey] = []

        for item in items {
            let descriptor = memberDescriptor(for: item)
            if groupedItems[descriptor.key] == nil {
                orderedKeys.append(descriptor.key)
                groupTitles[descriptor.key] = descriptor.title
            }
            groupedItems[descriptor.key, default: []].append(item)
        }

        return orderedKeys.prefix(memberCandidateDisplayLimit).enumerated().compactMap { index, key in
            guard let items = groupedItems[key],
                  let firstItem = items.first
            else {
                return nil
            }
            return candidate(
                from: firstItem,
                in: items,
                source: .user,
                index: index,
                goodsTypes: goodsTypes,
                conditionSignalsByItemID: conditionSignalsByItemID,
                titleOverride: groupTitles[key]
            )
        }
    }

    private static func candidate(
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

    private static func conditionSignalsByGoodsID(
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

    private static func fallbackSignals(
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

    private static func sheet(
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

    private static func title(for item: GoodsItem, source: HomeDiscoveryCandidateSource, goodsTypes: [GoodsType]) -> String {
        switch source {
        case .userTag:
            return memberTagTitle(from: item, goodsTypes: goodsTypes)
        case .haves:
            return item.title
        case .user:
            return masterDisplayName(for: item)
        }
    }

    private static func memberTagTitle(from item: GoodsItem, goodsTypes: [GoodsType]) -> String {
        let memberName = masterDisplayName(for: item)
        if let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first {
            return HomeDiscoveryTitleParser.joinedMemberTagTitle(member: memberName, tag: tag)
        }
        return memberName
    }

    private static func goodsStack(
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

    private static func memberTagDescriptor(for item: GoodsItem, goodsTypes: [GoodsType]) -> MemberTagDescriptor {
        let memberName = masterDisplayName(for: item)
        let memberKey = masterIdentityKey(for: item)
        guard let tag = HomeDiscoveryTagFormatter.displayTags(for: item, goodsTypes: goodsTypes, limit: 1).first else {
            return MemberTagDescriptor(
                key: MemberTagGroupKey(master: memberKey, tag: "", fallbackID: item.id),
                title: memberName
            )
        }
        return MemberTagDescriptor(
            key: MemberTagGroupKey(master: memberKey, tag: comparableTagName(tag), fallbackID: nil),
            title: HomeDiscoveryTitleParser.joinedMemberTagTitle(member: memberName, tag: tag)
        )
    }

    private static func memberDescriptor(for item: GoodsItem) -> MemberDescriptor {
        let memberName = masterDisplayName(for: item)
        let memberKey = masterIdentityKey(for: item)
        return MemberDescriptor(
            key: MemberGroupKey(master: memberKey, fallbackID: nil),
            title: memberName
        )
    }

    private static func masterIdentityKey(for item: GoodsItem) -> String {
        if let memberID = item.memberID {
            return "character:\(memberID.uuidString.lowercased())"
        }
        if let groupID = item.groupID {
            return "group:\(groupID.uuidString.lowercased())"
        }
        return "item:\(item.id.uuidString.lowercased())"
    }

    private static func masterDisplayName(for item: GoodsItem) -> String {
        if item.memberID != nil, let memberName = normalizedMasterName(item.memberName) {
            return memberName
        }
        if let groupName = normalizedMasterName(item.groupName) {
            return groupName
        }
        return item.memberID == nil ? "推し未設定" : "メンバー未設定"
    }

    private static func normalizedMasterName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func comparableTagName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
    }
}
