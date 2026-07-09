import Foundation
import MegrumCore

public final class SupabaseNotificationClient: @unchecked Sendable {
    static let nativePushDeviceConflictTarget = "user_id,push_provider,native_device_token"

    let client: SupabaseRESTClient
    let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadNotifications(userID: UUID, limit: Int = 100) async throws -> [MegrumNotification] {
        let rows: [NotificationRow] = try await client.fetchRows(
            from: "notifications",
            select: NotificationRow.select,
            queryItems: loadQueryItems(userID: userID, limit: limit)
        )
        return rows.map(\.notification)
    }

    @discardableResult
    public func markNotificationRead(
        userID: UUID,
        notificationID: UUID,
        readAt: Date = .now
    ) async throws -> MegrumNotification? {
        let rows: [NotificationRow] = try await client.updateRows(
            in: "notifications",
            values: MarkReadPayload(readAt: notificationISOTimestamp(readAt)),
            select: NotificationRow.select,
            queryItems: markReadQueryItems(userID: userID, notificationID: notificationID)
        )
        return rows.first?.notification
    }

    @discardableResult
    public func markAllNotificationsRead(userID: UUID, readAt: Date = .now) async throws -> [MegrumNotification] {
        let rows: [NotificationRow] = try await client.updateRows(
            in: "notifications",
            values: MarkReadPayload(readAt: notificationISOTimestamp(readAt)),
            select: NotificationRow.select,
            queryItems: markAllReadQueryItems(userID: userID)
        )
        return rows.map(\.notification)
    }

    public func loadPushNotificationsEnabled(userID: UUID) async throws -> Bool {
        try await loadNotificationSettings(userID: userID).pushEnabled
    }

    public func loadNotificationSettings(userID: UUID) async throws -> UserNotificationSettings {
        let rows: [NotificationSettingRow] = try await client.fetchRows(
            from: "user_notification_settings",
            select: NotificationSettingRow.select,
            queryItems: pushSettingQueryItems(userID: userID)
        )
        return rows.first?.settings ?? UserNotificationSettings()
    }

    @discardableResult
    public func setPushNotificationsEnabled(userID: UUID, enabled: Bool) async throws -> Bool {
        let rows: [NotificationSettingRow] = try await client.upsertRows(
            into: "user_notification_settings",
            values: [NotificationSettingPayload(userID: userID, pushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
        return rows.first?.pushEnabled ?? enabled
    }

    @discardableResult
    public func setGroomActivityPushNotificationsEnabled(userID: UUID, enabled: Bool) async throws -> UserNotificationSettings {
        let rows: [NotificationSettingRow] = try await client.upsertRows(
            into: "user_notification_settings",
            values: [GroomActivityNotificationSettingPayload(userID: userID, groomActivityPushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
        return rows.first?.settings ?? UserNotificationSettings(groomActivityPushEnabled: enabled)
    }

    @discardableResult
    public func setChatroomActivityPushNotificationsEnabled(userID: UUID, enabled: Bool) async throws -> UserNotificationSettings {
        let rows: [NotificationSettingRow] = try await client.upsertRows(
            into: "user_notification_settings",
            values: [ChatroomActivityNotificationSettingPayload(userID: userID, chatroomActivityPushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
        return rows.first?.settings ?? UserNotificationSettings(chatroomActivityPushEnabled: enabled)
    }

    @discardableResult
    public func setMeguriSubscriptionPushSettings(
        userID: UUID,
        input: MeguriSubscriptionPushSettingsInput
    ) async throws -> UserNotificationSettings {
        let rows: [NotificationSettingRow] = try await client.upsertRows(
            into: "user_notification_settings",
            values: [
                MeguriSubscriptionNotificationSettingPayload(
                    userID: userID,
                    groomOshiPushEnabled: input.groomOshiPushEnabled,
                    groomNearbyPushEnabled: input.groomNearbyPushEnabled,
                    chatroomOshiPushEnabled: input.chatroomOshiPushEnabled,
                    chatroomNearbyPushEnabled: input.chatroomNearbyPushEnabled
                )
            ],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
        return rows.first?.settings ?? UserNotificationSettings(
            groomOshiPushEnabled: input.groomOshiPushEnabled,
            groomNearbyPushEnabled: input.groomNearbyPushEnabled,
            chatroomOshiPushEnabled: input.chatroomOshiPushEnabled,
            chatroomNearbyPushEnabled: input.chatroomNearbyPushEnabled
        )
    }

    /// 圏内通知の基準位置を更新する（圏内通知オプトイン時のみ呼ぶ）。
    public func updatePushNotificationLocation(
        userID: UUID,
        latitude: Double,
        longitude: Double,
        updatedAt: Date = .now
    ) async throws {
        let _: [NotificationSettingRow] = try await client.upsertRows(
            into: "user_notification_settings",
            values: [
                PushNotificationLocationPayload(
                    userID: userID,
                    pushLocationLat: latitude,
                    pushLocationLng: longitude,
                    pushLocationUpdatedAt: notificationISOTimestamp(updatedAt)
                )
            ],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
    }

    /// FB8-7: 推し(L1)ごとの圏内グルーム通知設定を読む。行が無ければ既定（通知ON・全メンバー）。iter1226.388。
    public func loadGroomNotifyPrefs(userID: UUID) async throws -> [GroomNotifyPref] {
        let rows: [GroomNotifyPrefRow] = try await client.fetchRows(
            from: "user_groom_notify_prefs",
            select: GroomNotifyPrefRow.select,
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
            ]
        )
        return rows.map(\.pref)
    }

    @discardableResult
    public func setGroomNotifyPref(
        userID: UUID,
        groupID: UUID,
        enabled: Bool,
        notifyAllMembers: Bool,
        memberCharacterIDs: [UUID],
        updatedAt: Date = .now
    ) async throws -> GroomNotifyPref {
        let rows: [GroomNotifyPrefRow] = try await client.upsertRows(
            into: "user_groom_notify_prefs",
            values: [
                GroomNotifyPrefPayload(
                    userID: userID,
                    groupID: groupID,
                    enabled: enabled,
                    notifyAllMembers: notifyAllMembers,
                    memberCharacterIds: memberCharacterIDs,
                    updatedAt: notificationISOTimestamp(updatedAt)
                )
            ],
            select: GroomNotifyPrefRow.select,
            onConflict: "user_id,group_id"
        )
        return rows.first?.pref ?? GroomNotifyPref(
            groupID: groupID,
            enabled: enabled,
            notifyAllMembers: notifyAllMembers,
            memberCharacterIDs: memberCharacterIDs
        )
    }

    /// FB(iter1226.390): 1km圏内で推し一致したグルームを遭遇として記録する（プレミアム圏外閲覧用）。
    public func recordGroomEncounters(userID: UUID, groomPostIDs: [UUID]) async throws {
        guard !groomPostIDs.isEmpty else { return }
        let payloads = groomPostIDs.map { GroomEncounterPayload(userID: userID, groomPostID: $0) }
        let _: [GroomEncounterRow] = try await client.upsertRows(
            into: "groom_encounters",
            values: payloads,
            select: GroomEncounterRow.select,
            onConflict: "user_id,groom_post_id"
        )
    }

    @discardableResult
    public func registerNativePushDevice(
        userID: UUID,
        deviceToken: String,
        appVersion: String? = nil,
        seenAt: Date = .now
    ) async throws -> UUID? {
        let rows: [NotificationDeviceRow] = try await client.upsertRows(
            into: "notification_devices",
            values: [
                NativePushDevicePayload(
                    userID: userID,
                    deviceToken: deviceToken,
                    appVersion: appVersion,
                    seenAt: seenAt
                )
            ],
            select: NotificationDeviceRow.select,
            onConflict: Self.nativePushDeviceConflictTarget
        )
        return rows.first?.id
    }

    @discardableResult
    public func revokeNativePushDevice(
        userID: UUID,
        deviceToken: String,
        revokedAt: Date = .now
    ) async throws -> UUID? {
        let rows: [NotificationDeviceRow] = try await client.updateRows(
            in: "notification_devices",
            values: RevokeNativePushDevicePayload(revokedAt: notificationISOTimestamp(revokedAt)),
            select: NotificationDeviceRow.select,
            queryItems: revokeNativePushDeviceQueryItems(userID: userID, deviceToken: deviceToken)
        )
        return rows.first?.id
    }

    public static func nativeDeviceTokenString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
