import Foundation

/// FB(iter1226.390): 推し(L1グループ)ごとの圏内グルーム通知設定。
/// - `enabled`: このグループの通知を出すか（既定 true）。
/// - `notifyAllMembers`: true=グループ全体（メンバー未設定投稿も含む）／false=`memberCharacterIDs` のみ。
/// - `memberCharacterIDs`: `notifyAllMembers=false` のとき通知対象にするメンバー(L2)。
public struct GroomNotifyPref: Identifiable, Codable, Hashable, Sendable {
    public var groupID: UUID
    public var enabled: Bool
    public var notifyAllMembers: Bool
    public var memberCharacterIDs: [UUID]

    public var id: UUID { groupID }

    public init(
        groupID: UUID,
        enabled: Bool = true,
        notifyAllMembers: Bool = true,
        memberCharacterIDs: [UUID] = []
    ) {
        self.groupID = groupID
        self.enabled = enabled
        self.notifyAllMembers = notifyAllMembers
        self.memberCharacterIDs = memberCharacterIDs
    }

    /// このグルーム（グループ・メンバー）が通知対象か判定する。
    public func notifies(characterID: UUID?) -> Bool {
        guard enabled else { return false }
        if notifyAllMembers { return true }
        guard let characterID else { return false }
        return memberCharacterIDs.contains(characterID)
    }
}
