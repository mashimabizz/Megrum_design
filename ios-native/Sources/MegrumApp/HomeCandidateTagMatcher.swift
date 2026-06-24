import Foundation
import MegrumData

enum HomeCandidateTagMatcher {
    static func count(
        itemID: UUID,
        matchingRows: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> Int {
        let itemTags = normalizedSet(tagsByInventoryID[itemID] ?? [])
        guard !itemTags.isEmpty else {
            return 0
        }
        let matchingTags = matchingRows.reduce(into: Set<String>()) { result, row in
            result.formUnion(normalizedSet(tagsByInventoryID[row.id] ?? []))
        }
        return itemTags.intersection(matchingTags).count
    }

    static func normalizedSet(_ tags: [SupabaseHomeInventoryTagRow]) -> Set<String> {
        Set(tags.compactMap { tag in
            tag.label
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { value in
                    let withoutHash = value.hasPrefix("#") ? String(value.dropFirst()) : value
                    let normalized = withoutHash.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return normalized.isEmpty ? nil : normalized
                }
        })
    }
}
