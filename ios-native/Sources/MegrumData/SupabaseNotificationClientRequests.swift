import Foundation

extension SupabaseNotificationClient {
    public func makeLoadNotificationsRequest(userID: UUID, limit: Int = 100) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/notifications",
            queryItems: [
                URLQueryItem(name: "select", value: NotificationRow.select)
            ] + loadQueryItems(userID: userID, limit: limit)
        )
    }

    public func makeMarkReadRequest(
        userID: UUID,
        notificationID: UUID,
        readAt: Date
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/notifications",
            queryItems: [
                URLQueryItem(name: "select", value: NotificationRow.select)
            ] + markReadQueryItems(userID: userID, notificationID: notificationID),
            method: "PATCH",
            body: encoder.encode(MarkReadPayload(readAt: notificationISOTimestamp(readAt))),
            prefer: "return=representation"
        )
    }

    public func makeMarkAllReadRequest(userID: UUID, readAt: Date) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/notifications",
            queryItems: [
                URLQueryItem(name: "select", value: NotificationRow.select)
            ] + markAllReadQueryItems(userID: userID),
            method: "PATCH",
            body: encoder.encode(MarkReadPayload(readAt: notificationISOTimestamp(readAt))),
            prefer: "return=representation"
        )
    }

    public func makeLoadPushSettingRequest(userID: UUID) throws -> URLRequest {
        try makeLoadNotificationSettingsRequest(userID: userID)
    }

    public func makeLoadNotificationSettingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_notification_settings",
            queryItems: [
                URLQueryItem(name: "select", value: NotificationSettingRow.select)
            ] + pushSettingQueryItems(userID: userID)
        )
    }

    public func makeSetPushSettingRequest(userID: UUID, enabled: Bool) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "user_notification_settings",
            values: [NotificationSettingPayload(userID: userID, pushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
    }

    public func makeSetGroomActivityPushSettingRequest(userID: UUID, enabled: Bool) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "user_notification_settings",
            values: [GroomActivityNotificationSettingPayload(userID: userID, groomActivityPushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
    }

    public func makeSetChatroomActivityPushSettingRequest(userID: UUID, enabled: Bool) throws -> URLRequest {
        try client.makeUpsertRequest(
            into: "user_notification_settings",
            values: [ChatroomActivityNotificationSettingPayload(userID: userID, chatroomActivityPushEnabled: enabled)],
            select: NotificationSettingRow.select,
            onConflict: "user_id"
        )
    }

    public func makeRegisterNativePushDeviceRequest(
        userID: UUID,
        deviceToken: String,
        appVersion: String? = nil,
        seenAt: Date = .now
    ) throws -> URLRequest {
        try client.makeUpsertRequest(
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
    }

    public func makeRevokeNativePushDeviceRequest(
        userID: UUID,
        deviceToken: String,
        revokedAt: Date = .now
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/notification_devices",
            queryItems: [
                URLQueryItem(name: "select", value: NotificationDeviceRow.select)
            ] + revokeNativePushDeviceQueryItems(userID: userID, deviceToken: deviceToken),
            method: "PATCH",
            body: encoder.encode(RevokeNativePushDevicePayload(revokedAt: notificationISOTimestamp(revokedAt))),
            prefer: "return=representation"
        )
    }

    func loadQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    func markReadQueryItems(userID: UUID, notificationID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(notificationID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    func markAllReadQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "read_at", value: "is.null")
        ]
    }

    func pushSettingQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func revokeNativePushDeviceQueryItems(userID: UUID, deviceToken: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "push_provider", value: "eq.apns"),
            URLQueryItem(name: "native_device_token", value: "eq.\(deviceToken.normalizedNativeDeviceToken)"),
            URLQueryItem(name: "revoked_at", value: "is.null")
        ]
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
