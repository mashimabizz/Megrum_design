import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateRowMapper {
    static func isMarketAvailable(_ row: SupabaseHomeGoodsRow) -> Bool {
        row.marketAvailableQuantity > 0
    }

    static func isTestUser(_ row: SupabaseHomeUserRow) -> Bool {
        if row.isTestAccount == true {
            return true
        }
        guard let handle = row.handle?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return false
        }
        return handle.hasPrefix("codex_mm_")
    }

    static func makeGoodsItem(
        from row: SupabaseHomeGoodsRow,
        tags: [SupabaseHomeInventoryTagRow],
        ownerPrefecture: String?,
        ownerPaymentMethods: [String] = [],
        ownerPaymentNote: String? = nil,
        ownerHasMegrumPlus: Bool = false
    ) -> GoodsItem {
        makeGoodsItem(
            from: row,
            tags: tags,
            ownerUser: nil,
            fallbackOwnerPrefecture: ownerPrefecture,
            fallbackOwnerPaymentMethods: ownerPaymentMethods,
            fallbackOwnerPaymentNote: ownerPaymentNote,
            ownerHasMegrumPlus: ownerHasMegrumPlus
        )
    }

    static func makeGoodsItem(
        from row: SupabaseHomeGoodsRow,
        tags: [SupabaseHomeInventoryTagRow],
        ownerUser: SupabaseHomeUserRow?,
        ownerHasMegrumPlus: Bool = false
    ) -> GoodsItem {
        makeGoodsItem(
            from: row,
            tags: tags,
            ownerUser: ownerUser,
            fallbackOwnerPrefecture: ownerUser?.primaryArea,
            fallbackOwnerPaymentMethods: ownerUser?.paymentMethods ?? [],
            fallbackOwnerPaymentNote: ownerUser?.paymentNote,
            ownerHasMegrumPlus: ownerHasMegrumPlus
        )
    }

    private static func makeGoodsItem(
        from row: SupabaseHomeGoodsRow,
        tags: [SupabaseHomeInventoryTagRow],
        ownerUser: SupabaseHomeUserRow?,
        fallbackOwnerPrefecture: String?,
        fallbackOwnerPaymentMethods: [String],
        fallbackOwnerPaymentNote: String?,
        ownerHasMegrumPlus: Bool
    ) -> GoodsItem {
        GoodsItem(
            id: row.id,
            ownerID: row.userId,
            groupID: row.groupId,
            memberID: row.characterId,
            goodsTypeID: row.goodsTypeId,
            groupName: row.groupName,
            memberName: row.characterName,
            goodsTypeName: row.goodsTypeName,
            title: row.title,
            imageURL: row.photoUrls.compactMap(URL.init(string:)).first,
            tags: tags.compactMap { tag in
                guard let label = tag.label?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !label.isEmpty
                else {
                    return nil
                }
                return GoodsTag(id: tag.tagId, name: label)
            },
            quantity: max(1, row.marketAvailableQuantity),
            exchangeMethod: ExchangeMethod(exchangeTypeValue: row.exchangeType),
            ownerPrefecture: fallbackOwnerPrefecture,
            ownerDisplayName: trimmed(ownerUser?.displayName) ?? trimmed(ownerUser?.handle),
            ownerHandle: trimmed(ownerUser?.handle),
            ownerAvatarURL: ownerUser?.avatarUrl.flatMap(URL.init(string:)),
            ownerGender: ownerUser?.gender.flatMap(UserGender.init(rawValue:)),
            ownerAge: ownerUser?.age,
            ownerAverageStars: ownerUser?.averageStars,
            ownerEvaluationCount: ownerUser?.evaluationCount,
            ownerCompletedTradeCount: ownerUser?.completedTradeCount,
            ownerPaymentMethods: HomeCandidatePaymentPolicy.methods(fallbackOwnerPaymentMethods),
            ownerPaymentNote: fallbackOwnerPaymentNote,
            ownerHasMegrumPlus: ownerHasMegrumPlus
        )
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension SupabaseHomeGoodsRow {
    var marketAvailableQuantity: Int {
        if let marketAvailableQty {
            return max(0, marketAvailableQty)
        }
        return max(0, (quantity ?? 1) - (lockedQty ?? 0))
    }
}
