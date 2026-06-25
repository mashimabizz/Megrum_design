import Foundation
import MegrumCore

extension HomeDiscoveryCandidateFactory {
    struct MemberTagGroupKey: Hashable {
        var master: String
        var tag: String
        var fallbackID: UUID?
    }

    struct MemberGroupKey: Hashable {
        var master: String
        var fallbackID: UUID?
    }

    struct MemberTagDescriptor {
        var key: MemberTagGroupKey
        var title: String
    }

    struct MemberDescriptor {
        var key: MemberGroupKey
        var title: String
    }

    static func memberTagCandidates(
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

    static func memberCandidates(
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

    static func memberTagDescriptor(for item: GoodsItem, goodsTypes: [GoodsType]) -> MemberTagDescriptor {
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

    static func memberDescriptor(for item: GoodsItem) -> MemberDescriptor {
        let memberName = masterDisplayName(for: item)
        let memberKey = masterIdentityKey(for: item)
        return MemberDescriptor(
            key: MemberGroupKey(master: memberKey, fallbackID: nil),
            title: memberName
        )
    }

    static func masterIdentityKey(for item: GoodsItem) -> String {
        if let memberID = item.memberID {
            return "character:\(memberID.uuidString.lowercased())"
        }
        if let groupID = item.groupID {
            return "group:\(groupID.uuidString.lowercased())"
        }
        return "item:\(item.id.uuidString.lowercased())"
    }

    static func masterDisplayName(for item: GoodsItem) -> String {
        if item.memberID != nil, let memberName = normalizedMasterName(item.memberName) {
            return memberName
        }
        if let groupName = normalizedMasterName(item.groupName) {
            return groupName
        }
        return item.memberID == nil ? "推し未設定" : "メンバー未設定"
    }

    static func normalizedMasterName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func comparableTagName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
    }
}
