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
    static let select = "push_enabled,groom_activity_push_enabled,chatroom_activity_push_enabled"
    var pushEnabled: Bool
    var groomActivityPushEnabled: Bool?
    var chatroomActivityPushEnabled: Bool?

    var settings: UserNotificationSettings {
        UserNotificationSettings(
            pushEnabled: pushEnabled,
            groomActivityPushEnabled: groomActivityPushEnabled ?? true,
            chatroomActivityPushEnabled: chatroomActivityPushEnabled ?? true
        )
    }
}

struct NotificationDeviceRow: Decodable, Sendable {
    static let select = "id"
    var id: UUID
}
