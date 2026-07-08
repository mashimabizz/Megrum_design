import Foundation

struct MarkReadPayload: Encodable, Sendable {
    var readAt: String
}

struct NotificationSettingPayload: Encodable, Sendable {
    var userID: UUID
    var pushEnabled: Bool
}

struct GroomActivityNotificationSettingPayload: Encodable, Sendable {
    var userID: UUID
    var groomActivityPushEnabled: Bool
}

struct ChatroomActivityNotificationSettingPayload: Encodable, Sendable {
    var userID: UUID
    var chatroomActivityPushEnabled: Bool
}

struct MeguriSubscriptionNotificationSettingPayload: Encodable, Sendable {
    var userID: UUID
    var groomOshiPushEnabled: Bool
    var groomNearbyPushEnabled: Bool
    var chatroomOshiPushEnabled: Bool
    var chatroomNearbyPushEnabled: Bool
}

struct PushNotificationLocationPayload: Encodable, Sendable {
    var userID: UUID
    var pushLocationLat: Double
    var pushLocationLng: Double
    var pushLocationUpdatedAt: String
}

struct RevokeNativePushDevicePayload: Encodable, Sendable {
    var revokedAt: String
}

struct NativePushDevicePayload: Encodable, Sendable {
    var userID: UUID
    var platform: String
    var pushProvider: String
    var nativeDeviceToken: String
    var appVersion: String?
    var lastSeenAt: String

    init(userID: UUID, deviceToken: String, appVersion: String?, seenAt: Date) {
        self.userID = userID
        self.platform = "ios"
        self.pushProvider = "apns"
        self.nativeDeviceToken = deviceToken.normalizedNativeDeviceToken
        self.appVersion = SupabaseTextNormalizer.optional(appVersion)
        self.lastSeenAt = notificationISOTimestamp(seenAt)
    }

    enum CodingKeys: String, CodingKey {
        case userID
        case platform
        case pushProvider
        case nativeDeviceToken
        case appVersion
        case lastSeenAt
        case revokedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(platform, forKey: .platform)
        try container.encode(pushProvider, forKey: .pushProvider)
        try container.encode(nativeDeviceToken, forKey: .nativeDeviceToken)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encode(lastSeenAt, forKey: .lastSeenAt)
        try container.encodeNil(forKey: .revokedAt)
    }
}

/// FB8-7: 推し(L1)ごとの圏内グルーム通知設定 upsert ペイロード。iter1226.388。
struct GroomNotifyPrefPayload: Encodable, Sendable {
    var userID: UUID
    var groupID: UUID
    var enabled: Bool
    var membersOnly: Bool
    var updatedAt: String
}
