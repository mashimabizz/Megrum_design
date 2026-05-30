import Foundation
import MegrumCore

public final class SupabaseNotificationClient: @unchecked Sendable {
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

private func isoTimestamp(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
}
