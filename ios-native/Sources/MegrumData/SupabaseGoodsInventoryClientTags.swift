import Foundation
import MegrumCore

extension SupabaseGoodsInventoryClient {
    func goodsItemsWithTags(from rows: [GoodsInventoryRow]) async throws -> [GoodsItem] {
        let tagMap = try await loadGoodsTags(inventoryIDs: rows.map(\.id))
        return rows.map { row in
            var item = row.goodsItem
            item.tags = tagMap[row.id] ?? []
            return item
        }
    }

    func syncGoodsTagsIfNeeded(inventoryID: UUID, tagNames: [String]) async throws -> [GoodsTag] {
        let desiredNames = normalizedTagNames(tagNames)
        let existingTags = try await loadGoodsTags(inventoryIDs: [inventoryID])[inventoryID] ?? []
        let existingByName = existingTags.reduce(into: [String: GoodsTag]()) { result, tag in
            let key = tag.name.lowercased()
            if result[key] == nil {
                result[key] = tag
            }
        }
        let desiredKeys = Set(desiredNames.map { $0.lowercased() })

        for tag in existingTags where !desiredKeys.contains(tag.name.lowercased()) {
            try await detachGoodsTag(inventoryID: inventoryID, tagID: tag.id)
        }

        var synced: [GoodsTag] = []
        for name in desiredNames {
            if let existing = existingByName[name.lowercased()] {
                synced.append(existing)
            } else {
                synced.append(try await attachGoodsTag(inventoryID: inventoryID, rawLabel: name))
            }
        }
        return synced
    }

    func normalizedTagNames(_ tagNames: [String]) -> [String] {
        tagNames.reduce(into: []) { result, raw in
            guard result.count < 5, let normalized = normalizedTagName(raw) else {
                return
            }
            if !result.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                result.append(normalized)
            }
        }
    }

    func normalizedTagName(_ raw: String) -> String? {
        let normalized = SupabaseTextNormalizer.trimmed(raw)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
        let label = SupabaseTextNormalizer.trimmed(normalized)
        return label.isEmpty ? nil : String(label.prefix(50))
    }
}
