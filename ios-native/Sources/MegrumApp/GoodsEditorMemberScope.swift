import Foundation
import MegrumCore

enum GoodsEditorMemberScope {
    static func members(for group: OshiGroup?, from allMembers: [OshiCharacter]) -> [OshiCharacter] {
        guard let group, group.supportsMemberSelection else {
            return []
        }
        return allMembers.filter { $0.groupID == group.id }
    }

    static func memberIDs(for group: OshiGroup?, from allMembers: [OshiCharacter]) -> [UUID] {
        members(for: group, from: allMembers).map(\.id)
    }

    static func canUseMemberID(
        _ memberID: UUID?,
        group: OshiGroup?,
        members allMembers: [OshiCharacter]
    ) -> Bool {
        guard let memberID else {
            return true
        }
        return members(for: group, from: allMembers).contains { $0.id == memberID }
    }
}
