import Foundation
import MegrumCore

enum GoodsEditorTagSuggestionBuilder {
    private static let fallbackTags = [
        "会場限定",
        "未開封",
        "トレカ",
        "ラキドロ",
        "初回盤",
        "特典",
        "同種優先",
        "現地交換",
        "コンプ用",
        "被り"
    ]

    static func suggestions(
        groupID: UUID?,
        selectedTags: [String],
        inventory: [GoodsItem],
        wishes: [WishItem],
        limit: Int = 10
    ) -> [String] {
        guard let groupID, limit > 0 else {
            return []
        }

        let rankedHistoricalTags = historicalTagCounts(
            groupID: groupID,
            inventory: inventory,
            wishes: wishes
        )
        .sorted { lhs, rhs in
            lhs.value == rhs.value
                ? lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
                : lhs.value > rhs.value
        }
        .map(\.key)

        return (rankedHistoricalTags + fallbackTags).reduce(into: [String]()) { result, tag in
            guard result.count < limit,
                  !selectedTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }),
                  !result.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame })
            else {
                return
            }
            result.append(tag)
        }
    }

    private static func historicalTagCounts(
        groupID: UUID,
        inventory: [GoodsItem],
        wishes: [WishItem]
    ) -> [String: Int] {
        var tagCounts: [String: Int] = [:]
        for item in inventory where item.groupID == groupID {
            appendTags(from: item, to: &tagCounts)
        }
        for item in wishes where item.groupID == groupID {
            appendTags(from: item, to: &tagCounts)
        }
        return tagCounts
    }

    private static func appendTags(from item: GoodsItem, to tagCounts: inout [String: Int]) {
        for tag in item.tags {
            tagCounts[tag.name, default: 0] += 1
        }
    }

    private static func appendTags(from item: WishItem, to tagCounts: inout [String: Int]) {
        for tag in item.tags {
            tagCounts[tag.name, default: 0] += 1
        }
    }
}
