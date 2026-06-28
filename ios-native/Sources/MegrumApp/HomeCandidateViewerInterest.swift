import Foundation
import MegrumCore
import MegrumData

struct HomeCandidateViewerInterest: Equatable, Sendable {
    var groupID: UUID?
    var characterID: UUID?
    var goodsTypeID: UUID?
    var isOshiFallback: Bool

    static func wish(_ row: SupabaseHomeGoodsRow) -> HomeCandidateViewerInterest {
        HomeCandidateViewerInterest(
            groupID: row.groupId,
            characterID: row.characterId,
            goodsTypeID: row.goodsTypeId,
            isOshiFallback: false
        )
    }

    static func oshiSelections(_ selections: [UserOshiSelection]) -> [HomeCandidateViewerInterest] {
        selections
            .sorted { lhs, rhs in
                lhs.priority < rhs.priority
            }
            .compactMap { selection in
                guard selection.groupID != nil || selection.characterID != nil else {
                    return nil
                }
                return HomeCandidateViewerInterest(
                    groupID: selection.groupID,
                    characterID: selection.characterID,
                    goodsTypeID: nil,
                    isOshiFallback: true
                )
            }
    }

    func matches(_ item: SupabaseHomeGoodsRow) -> Bool {
        fieldMatches(groupID, item.groupId)
            && fieldMatches(characterID, item.characterId)
            && fieldMatches(goodsTypeID, item.goodsTypeId)
    }

    func matchesMemberShelf(_ item: SupabaseHomeGoodsRow) -> Bool {
        if let characterID {
            return item.characterId == characterID
        }
        guard isOshiFallback,
              let groupID,
              item.groupId == groupID
        else {
            return false
        }
        return item.characterId == nil
    }

    private func fieldMatches(_ expected: UUID?, _ actual: UUID?) -> Bool {
        guard let expected else {
            return true
        }
        return expected == actual
    }
}
