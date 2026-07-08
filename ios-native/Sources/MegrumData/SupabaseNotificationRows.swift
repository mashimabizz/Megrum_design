import Foundation
import MegrumCore

struct NotificationRow: Decodable, Sendable {
    static let select = "id,kind,title,body,link_path,read_at,created_at"

    var id: UUID
    var kind: String
    var title: String
    var body: String?
    var linkPath: String?
    var readAt: Date?
    var createdAt: Date

    var notification: MegrumNotification {
        MegrumNotification(
            id: id,
            kind: MegrumNotificationKind(rawValue: kind) ?? .unknown,
            title: title,
            body: body,
            linkPath: linkPath,
            readAt: readAt,
            createdAt: createdAt
        )
    }
}

struct NotificationSettingRow: Decodable, Sendable {
    static let select = "push_enabled,groom_activity_push_enabled,chatroom_activity_push_enabled,"
        + "groom_oshi_push_enabled,groom_nearby_push_enabled,"
        + "chatroom_oshi_push_enabled,chatroom_nearby_push_enabled"
    var pushEnabled: Bool
    var groomActivityPushEnabled: Bool?
    var chatroomActivityPushEnabled: Bool?
    var groomOshiPushEnabled: Bool?
    var groomNearbyPushEnabled: Bool?
    var chatroomOshiPushEnabled: Bool?
    var chatroomNearbyPushEnabled: Bool?

    var settings: UserNotificationSettings {
        UserNotificationSettings(
            pushEnabled: pushEnabled,
            groomActivityPushEnabled: groomActivityPushEnabled ?? true,
            chatroomActivityPushEnabled: chatroomActivityPushEnabled ?? true,
            groomOshiPushEnabled: groomOshiPushEnabled ?? false,
            groomNearbyPushEnabled: groomNearbyPushEnabled ?? false,
            chatroomOshiPushEnabled: chatroomOshiPushEnabled ?? false,
            chatroomNearbyPushEnabled: chatroomNearbyPushEnabled ?? false
        )
    }
}

struct NotificationDeviceRow: Decodable, Sendable {
    static let select = "id"
    var id: UUID
}

/// FB8-7: 推し(L1)ごとの圏内グルーム通知設定行。iter1226.388。
struct GroomNotifyPrefRow: Decodable, Sendable {
    static let select = "group_id,enabled,members_only"
    var groupID: UUID
    var enabled: Bool
    var membersOnly: Bool

    var pref: GroomNotifyPref {
        GroomNotifyPref(groupID: groupID, enabled: enabled, membersOnly: membersOnly)
    }
}
