import Foundation
import MegrumCore

struct NotificationRow: Decodable, Sendable {
    static let select = "id,kind,title,body,link_path,read_at,created_at,"
        + "actor_user_id,actor_display_name,actor_avatar_url"

    var id: UUID
    var kind: String
    var title: String
    var body: String?
    var linkPath: String?
    var readAt: Date?
    var createdAt: Date
    // 注意：プロパティ名は convertFromSnakeCase の変換結果に合わせる（actor_user_id→actorUserId）。
    var actorUserId: UUID?
    var actorDisplayName: String?
    var actorAvatarUrl: String?

    var notification: MegrumNotification {
        MegrumNotification(
            id: id,
            kind: MegrumNotificationKind(rawValue: kind) ?? .unknown,
            title: title,
            body: body,
            linkPath: linkPath,
            readAt: readAt,
            createdAt: createdAt,
            actorUserID: actorUserId,
            actorDisplayName: actorDisplayName,
            actorAvatarURL: actorAvatarUrl.flatMap(URL.init(string:))
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

/// FB(iter1226.390): 推し(L1)ごとの圏内グルーム通知設定行。
/// 注意：プロパティ名は convertFromSnakeCase の変換結果に合わせる（group_id→groupId,
/// member_character_ids→memberCharacterIds）。`groupID`/`memberCharacterIDs` にすると復号に失敗する。iter1226.393。
struct GroomNotifyPrefRow: Decodable, Sendable {
    static let select = "group_id,enabled,notify_all_members,member_character_ids"
    var groupId: UUID
    var enabled: Bool
    var notifyAllMembers: Bool?
    var memberCharacterIds: [UUID]?

    var pref: GroomNotifyPref {
        GroomNotifyPref(
            groupID: groupId,
            enabled: enabled,
            notifyAllMembers: notifyAllMembers ?? true,
            memberCharacterIDs: memberCharacterIds ?? []
        )
    }
}

/// FB(iter1226.390): グルーム遭遇記録行。
struct GroomEncounterRow: Decodable, Sendable {
    static let select = "groom_post_id"
    var groomPostID: UUID
}
