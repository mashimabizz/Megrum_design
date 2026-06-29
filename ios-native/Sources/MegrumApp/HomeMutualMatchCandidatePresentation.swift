import Foundation
import MegrumCore
import MegrumData

struct HomeMutualMatchCandidateDisplaySide {
    var goodsItems: [GoodsItem]
    var displayItems: [HomeMutualMatchDisplayItemData]
}

enum HomeMutualMatchCandidatePresentation {
    static func displaySide(
        rows: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]],
        ownerUser: SupabaseHomeUserRow?,
        cashOptions: [SupabaseHomeListingWishOptionRow]
    ) -> HomeMutualMatchCandidateDisplaySide {
        let goodsItems = goodsItems(
            rows: rows,
            tagsByInventoryID: tagsByInventoryID,
            ownerUser: ownerUser
        )
        return HomeMutualMatchCandidateDisplaySide(
            goodsItems: goodsItems,
            displayItems: displayItems(
                goodsItems: goodsItems,
                cashOptions: cashOptions
            )
        )
    }

    static func goodsItems(
        rows: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]],
        ownerUser: SupabaseHomeUserRow?
    ) -> [GoodsItem] {
        Array(deduplicatedRows(rows).prefix(4)).map { row in
            HomeCandidateRowMapper.makeGoodsItem(
                from: row,
                tags: tagsByInventoryID[row.id] ?? [],
                ownerPrefecture: ownerUser?.primaryArea,
                ownerPaymentMethods: ownerUser?.paymentMethods ?? [],
                ownerPaymentNote: ownerUser?.paymentNote
            )
        }
    }

    static func displayItems(
        goodsItems: [GoodsItem],
        cashOptions: [SupabaseHomeListingWishOptionRow]
    ) -> [HomeMutualMatchDisplayItemData] {
        let cashItems = cashOptions.map { option in
            HomeMutualMatchDisplayItemData.cash(id: option.id, amount: option.cashAmount)
        }
        guard !cashItems.isEmpty else {
            return goodsItems.map(HomeMutualMatchDisplayItemData.goods)
        }
        return cashItems
    }

    static func stableID(
        viewerListingID: UUID,
        partnerListingID: UUID
    ) -> UUID {
        let seed = "\(viewerListingID.uuidString)-\(partnerListingID.uuidString)"
        let hash = seed.utf8.reduce(UInt64(5381)) { partial, byte in
            ((partial << 5) &+ partial) &+ UInt64(byte)
        }
        let tail = String(format: "%012llu", hash % 1_000_000_000_000)
        return UUID(uuidString: "00000000-0000-0000-0000-\(tail)")
            ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }

    static func displayName(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        trimmed(user?.displayName) ?? trimmed(user?.handle) ?? "相手\(fallbackID.uuidString.prefix(2))"
    }

    static func handle(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        trimmed(user?.handle) ?? "user_\(fallbackID.uuidString.prefix(4).lowercased())"
    }

    static func initial(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        let source = trimmed(user?.displayName) ?? trimmed(user?.handle)
        return source?.first.map { String($0).uppercased() }
            ?? String(fallbackID.uuidString.prefix(1)).uppercased()
    }

    static func ageRangeText(for age: Int?) -> String? {
        guard let age, age > 0 else {
            return nil
        }
        if age < 10 {
            return "10代未満"
        }
        let decade = min(age / 10 * 10, 100)
        return "\(decade)代"
    }

    static func evaluationSummaryText(for user: SupabaseHomeUserRow?) -> String? {
        guard let count = user?.evaluationCount else {
            return nil
        }
        if let average = user?.averageStars, count > 0 {
            return "評価\(count)件 ★\(String(format: "%.1f", average))"
        }
        return "評価\(count)件 ★—"
    }

    static func oshiText(for row: SupabaseHomeGoodsRow) -> String {
        if let characterName = trimmed(row.characterName) {
            return "\(characterName)推し"
        }
        if let groupName = trimmed(row.groupName) {
            return "\(groupName)推し"
        }
        return "推し未設定"
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func deduplicatedRows(_ rows: [SupabaseHomeGoodsRow]) -> [SupabaseHomeGoodsRow] {
        var seen: Set<UUID> = []
        var result: [SupabaseHomeGoodsRow] = []
        for row in rows where seen.insert(row.id).inserted {
            result.append(row)
        }
        return result
    }
}
