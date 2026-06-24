import Foundation
import MegrumCore

enum HomeDiscoveryTagFormatter {
    private static let fallbackGoodsTypeNames = [
        "トレカ",
        "生写真",
        "缶バッジ",
        "缶バ",
        "アクスタ",
        "アクリルスタンド",
        "キーホルダー",
        "ぬい"
    ]

    static func displayTags(for item: GoodsItem, goodsTypes: [GoodsType], limit: Int = 2) -> [String] {
        let goodsTypeNames = Set(goodsTypes.map { comparable($0.name) } + fallbackGoodsTypeNames.map(comparable))

        return item.tags.reduce(into: [String]()) { result, tag in
            guard result.count < limit else {
                return
            }
            guard let normalized = normalizedTagName(tag.name) else {
                return
            }
            guard !goodsTypeNames.contains(comparable(normalized)) else {
                return
            }
            let formatted = formattedTag(normalized)
            if !result.contains(where: { comparable($0) == comparable(formatted) }) {
                result.append(formatted)
            }
        }
    }

    static func matchingTagNames(for item: GoodsItem, goodsTypes: [GoodsType]) -> [String] {
        displayTags(for: item, goodsTypes: goodsTypes, limit: Int.max)
            .map(comparable)
    }

    private static func formattedTag(_ value: String) -> String {
        value.hasPrefix("#") ? value : "#\(value)"
    }

    private static func normalizedTagName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        let normalized = withoutHash.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func comparable(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
    }
}
