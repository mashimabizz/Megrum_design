import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingWantedOptionPreviewBuilder {
    static func previewItems(
        for option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [HomeIndividualListingWantedPreviewItem] {
        var previewInventoryByID: [UUID: SupabaseHomeGoodsRow] = [:]
        for row in previewInventory where previewInventoryByID[row.id] == nil {
            previewInventoryByID[row.id] = row
        }
        var rows: [SupabaseHomeGoodsRow] = []
        for id in option.wishIds {
            if let row = previewInventoryByID[id] {
                rows.append(row)
            }
        }
        if rows.isEmpty {
            rows = matchingItems
        }
        return orderedUnique(rows).map { row in
            HomeIndividualListingWantedPreviewItem(
                id: row.id,
                title: row.title,
                imageURL: GoodsPhotoURLResolver.displayURL(from: row.photoUrls),
                rawTagNames: rawTagNames(for: row.id, tagsByInventoryID: tagsByInventoryID)
            )
        }
    }

    private static func rawTagNames(
        for inventoryID: UUID,
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> [String] {
        tagsByInventoryID[inventoryID, default: []].compactMap { tag in
            tag.label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        }
    }

    private static func orderedUnique(_ rows: [SupabaseHomeGoodsRow]) -> [SupabaseHomeGoodsRow] {
        var seen: Set<UUID> = []
        var result: [SupabaseHomeGoodsRow] = []
        for row in rows where seen.insert(row.id).inserted {
            result.append(row)
        }
        return result
    }
}
