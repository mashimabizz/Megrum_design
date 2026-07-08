import Foundation

/// FB8-7: 推し(L1グループ)ごとの圏内グルーム通知設定。
/// 行が無ければ既定＝通知ON・全メンバー（`enabled=true`, `membersOnly=false`）。iter1226.388。
public struct GroomNotifyPref: Identifiable, Codable, Hashable, Sendable {
    public var groupID: UUID
    public var enabled: Bool
    public var membersOnly: Bool

    public var id: UUID { groupID }

    public init(groupID: UUID, enabled: Bool = true, membersOnly: Bool = false) {
        self.groupID = groupID
        self.enabled = enabled
        self.membersOnly = membersOnly
    }
}
