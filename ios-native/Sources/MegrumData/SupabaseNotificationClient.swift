import Foundation
import MegrumCore

public final class SupabaseNotificationClient: @unchecked Sendable {
    private static let nativePushDeviceConflictTarget = "user_id,push_provider,native_device_token"

    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

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
            values: MarkReadPayload(readAt: isoTimestamp(readAt)),
            select: NotificationRow.select,
            queryItems: markReadQueryItems(userID: userID, notificationID: notificationID)
        )
        return rows.first?.notification
    }

    @discardableResult
    public func markAllNotificationsRead(userID: UUID, readAt: Date = .now) async throws -> [MegrumNotification] {
        let rows: [NotificationRow] = try await client.updateRows(
            in: "notifications",
            values: MarkReadPayload(readAt: isoTimestamp(readAt)),
            select: NotificationRow.select,
            queryItems: markAllReadQueryItems(userID: userID)
        )
        return rows.map(\.notification)
    }

    public func loadPushNotificationsEnabled(userID: UUID) async throws -> Bool {
        let rows: [NotificationSettingRow] = try await client.fetchRows(
            from: "user_notification_settings",
            select: NotificationSettingRow.select,
            queryItems: pushSettingQueryItems(userID: userID)
        )
        return rows.first?.pushEnabled ?? true
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
            values: RevokeNativePushDevicePayload(revokedAt: isoTimestamp(revokedAt)),
            select: NotificationDeviceRow.select,
            queryItems: revokeNativePushDeviceQueryItems(userID: userID, deviceToken: deviceToken)
        )
        return rows.first?.id
    }

    public static func nativeDeviceTokenString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

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
            body: encoder.encode(MarkReadPayload(readAt: isoTimestamp(readAt))),
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
            body: encoder.encode(MarkReadPayload(readAt: isoTimestamp(readAt))),
            prefer: "return=representation"
        )
    }

    public func makeLoadPushSettingRequest(userID: UUID) throws -> URLRequest {
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
            body: encoder.encode(RevokeNativePushDevicePayload(revokedAt: isoTimestamp(revokedAt))),
            prefer: "return=representation"
        )
    }

    private func loadQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    private func markReadQueryItems(userID: UUID, notificationID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(notificationID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    private func markAllReadQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "read_at", value: "is.null")
        ]
    }

    private func pushSettingQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func revokeNativePushDeviceQueryItems(userID: UUID, deviceToken: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "push_provider", value: "eq.apns"),
            URLQueryItem(name: "native_device_token", value: "eq.\(deviceToken.normalizedNativeDeviceToken)"),
            URLQueryItem(name: "revoked_at", value: "is.null")
        ]
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct NotificationRow: Decodable, Sendable {
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

private struct MarkReadPayload: Encodable, Sendable {
    var readAt: String
}

private struct NotificationSettingRow: Decodable, Sendable {
    static let select = "push_enabled"
    var pushEnabled: Bool
}

private struct NotificationSettingPayload: Encodable, Sendable {
    var userID: UUID
    var pushEnabled: Bool
}

private struct NotificationDeviceRow: Decodable, Sendable {
    static let select = "id"
    var id: UUID
}

private struct RevokeNativePushDevicePayload: Encodable, Sendable {
    var revokedAt: String
}

private struct NativePushDevicePayload: Encodable, Sendable {
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
        self.appVersion = appVersion?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        self.lastSeenAt = isoTimestamp(seenAt)
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

private func isoTimestamp(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
}

private extension String {
    var normalizedNativeDeviceToken: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .lowercased()
    }

    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
