import Foundation
import MegrumData

enum HomeCandidateGoodsMatchPolicy {
    static func wishRow(_ wish: SupabaseHomeGoodsRow, matches item: SupabaseHomeGoodsRow) -> Bool {
        fieldMatches(wish.groupId, item.groupId)
            && fieldMatches(confirmedCharacterID(wish), confirmedCharacterID(item))
            && fieldMatches(wish.goodsTypeId, item.goodsTypeId)
    }

    static func wishRowHasSameConfirmedCharacter(
        _ wish: SupabaseHomeGoodsRow,
        _ item: SupabaseHomeGoodsRow
    ) -> Bool {
        guard let wishCharacterID = confirmedCharacterID(wish),
              let itemCharacterID = confirmedCharacterID(item)
        else {
            return false
        }
        return wishCharacterID == itemCharacterID
    }

    static func fieldMatches(_ expected: UUID?, _ actual: UUID?) -> Bool {
        guard let expected else {
            return true
        }
        return expected == actual
    }

    private static func confirmedCharacterID(_ row: SupabaseHomeGoodsRow) -> UUID? {
        row.characterId
    }
}
