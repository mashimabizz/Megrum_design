import Foundation
import MegrumCore

/// シリーズ候補のランキング（iter1226.413 拡張）：
/// ①同じグループでよく使うシリーズ（使用頻度順）
/// ②他のグループも含め自分がよく使うシリーズ（「会場限定」等の横断タグを拾う）
/// ③定番フォールバック
/// の3層。グループ未選択時も②③を返す（従来は空だった）。
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
        guard limit > 0 else {
            return []
        }

        let sameGroupTags = groupID.map {
            rankedTags(counts: historicalTagCounts(groupID: $0, inventory: inventory, wishes: wishes))
        } ?? []
        let ownUsageTags = rankedTags(
            counts: historicalTagCounts(groupID: nil, inventory: inventory, wishes: wishes)
        )

        return (sameGroupTags + ownUsageTags + fallbackTags).reduce(into: [String]()) { result, tag in
            guard result.count < limit,
                  !selectedTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }),
                  !result.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame })
            else {
                return
            }
            result.append(tag)
        }
    }

    private static func rankedTags(counts: [String: Int]) -> [String] {
        counts
            .sorted { lhs, rhs in
                lhs.value == rhs.value
                    ? lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
                    : lhs.value > rhs.value
            }
            .map(\.key)
    }

    /// groupID 指定時はそのグループ内、nil なら全グループの自分の使用回数を数える。
    private static func historicalTagCounts(
        groupID: UUID?,
        inventory: [GoodsItem],
        wishes: [WishItem]
    ) -> [String: Int] {
        var tagCounts: [String: Int] = [:]
        for item in inventory where groupID == nil || item.groupID == groupID {
            appendTags(from: item, to: &tagCounts)
        }
        for item in wishes where groupID == nil || item.groupID == groupID {
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
