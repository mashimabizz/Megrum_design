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
