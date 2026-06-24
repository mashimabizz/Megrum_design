import Foundation

public final class SupabaseActivityWindowClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder
    private let dateFormatter: ISO8601DateFormatter

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
        self.dateFormatter = Self.makeDateFormatter()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
        self.dateFormatter = Self.makeDateFormatter()
    }

    public func loadActivityWindows(
        userID: UUID,
        status: SupabaseActivityWindowStatus? = nil,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 50
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.fetchRows(
            from: "activity_windows",
            select: ActivityWindowRow.select,
            queryItems: activityWindowQueryItems(
                userID: userID,
                userFilter: "eq",
                status: status,
                from: from,
                to: to,
                limit: limit
            )
        )
        return rows.map(\.activityWindow)
    }

    public func loadVisibleActivityWindows(
        excludingUserID userID: UUID,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 500
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.fetchRows(
            from: "activity_windows",
            select: ActivityWindowRow.select,
            queryItems: activityWindowQueryItems(
                userID: userID,
                userFilter: "neq",
                status: .enabled,
                from: from,
                to: to,
                limit: limit
            )
        )
        return rows.map(\.activityWindow)
    }

    public func createActivityWindow(
        userID: UUID,
        input: SupabaseActivityWindowCreateInput
    ) async throws -> SupabaseActivityWindow {
        try validateCreateInput(input)
        let rows: [ActivityWindowRow] = try await client.insertRows(
            into: "activity_windows",
            values: [ActivityWindowCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ActivityWindowRow.select
        )
        guard let activityWindow = rows.first?.activityWindow else {
            throw SupabaseActivityWindowClientError.malformedResponse
        }
        return activityWindow
    }

    public func updateActivityWindow(
        userID: UUID,
        activityWindowID: UUID,
        input: SupabaseActivityWindowUpdateInput
    ) async throws -> SupabaseActivityWindow? {
        let payload = try ActivityWindowUpdatePayload(input: input, dateFormatter: dateFormatter)
        let rows: [ActivityWindowRow] = try await client.updateRows(
            in: "activity_windows",
            values: payload,
            select: ActivityWindowRow.select,
            queryItems: ownedActivityWindowQueryItems(userID: userID, activityWindowID: activityWindowID)
        )
        return rows.first?.activityWindow
    }

    @discardableResult
    public func disableOtherEnabledActivityWindows(
        userID: UUID,
        keeping activityWindowID: UUID
    ) async throws -> [SupabaseActivityWindow] {
        let rows: [ActivityWindowRow] = try await client.updateRows(
            in: "activity_windows",
            values: ActivityWindowStatusPayload(status: .disabled),
            select: ActivityWindowRow.select,
            queryItems: otherEnabledActivityWindowQueryItems(userID: userID, keeping: activityWindowID)
        )
        return rows.map(\.activityWindow)
    }

    public func loadLocalModeSettings(userID: UUID) async throws -> SupabaseLocalModeSettings? {
        let rows: [LocalModeSettingsRow] = try await client.fetchRows(
            from: "user_local_mode_settings",
            select: LocalModeSettingsRow.select,
            queryItems: localModeSettingsQueryItems(userID: userID)
        )
        return rows.first?.settings
    }

    public func upsertLocalModeSettings(
        userID: UUID,
        input: SupabaseLocalModeSettingsUpsertInput
    ) async throws -> SupabaseLocalModeSettings {
        let payload = try LocalModeSettingsUpsertPayload(userID: userID, input: input)
        let rows: [LocalModeSettingsRow] = try await client.upsertRows(
            into: "user_local_mode_settings",
            values: [payload],
            select: LocalModeSettingsRow.select,
            onConflict: "user_id"
        )
        guard let settings = rows.first?.settings else {
            throw SupabaseActivityWindowClientError.malformedResponse
        }
        return settings
    }

    public func makeLoadActivityWindowsRequest(
        userID: UUID,
        status: SupabaseActivityWindowStatus? = nil,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 50
    ) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + activityWindowQueryItems(
                    userID: userID,
                    userFilter: "eq",
                    status: status,
                    from: from,
                    to: to,
                    limit: limit
                )
        )
    }

    public func makeLoadVisibleActivityWindowsRequest(
        excludingUserID userID: UUID,
        from: Date? = nil,
        to: Date? = nil,
        limit: Int = 500
    ) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + activityWindowQueryItems(
                    userID: userID,
                    userFilter: "neq",
                    status: .enabled,
                    from: from,
                    to: to,
                    limit: limit
                )
        )
    }

    public func makeCreateActivityWindowRequest(
        userID: UUID,
        input: SupabaseActivityWindowCreateInput
    ) throws -> URLRequest {
        try validateCreateInput(input)
        return try client.makeInsertRequest(
            into: "activity_windows",
            values: [ActivityWindowCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ActivityWindowRow.select
        )
    }

    public func makeUpdateActivityWindowRequest(
        userID: UUID,
        activityWindowID: UUID,
        input: SupabaseActivityWindowUpdateInput
    ) throws -> URLRequest {
        let payload = try ActivityWindowUpdatePayload(input: input, dateFormatter: dateFormatter)
        return try client.makeMutationRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + ownedActivityWindowQueryItems(userID: userID, activityWindowID: activityWindowID),
            method: "PATCH",
            body: encoder.encode(payload),
            prefer: "return=representation"
        )
    }

    public func makeDisableOtherEnabledActivityWindowsRequest(
        userID: UUID,
        keeping activityWindowID: UUID
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: ActivityWindowRow.select)]
                + otherEnabledActivityWindowQueryItems(userID: userID, keeping: activityWindowID),
            method: "PATCH",
            body: encoder.encode(ActivityWindowStatusPayload(status: .disabled)),
            prefer: "return=representation"
        )
    }

    public func makeLoadLocalModeSettingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_local_mode_settings",
            queryItems: [URLQueryItem(name: "select", value: LocalModeSettingsRow.select)]
                + localModeSettingsQueryItems(userID: userID)
        )
    }

    public func makeUpsertLocalModeSettingsRequest(
        userID: UUID,
        input: SupabaseLocalModeSettingsUpsertInput
    ) throws -> URLRequest {
        let payload = try LocalModeSettingsUpsertPayload(userID: userID, input: input)
        return try client.makeUpsertRequest(
            into: "user_local_mode_settings",
            values: [payload],
            select: LocalModeSettingsRow.select,
            onConflict: "user_id"
        )
    }

    private func activityWindowQueryItems(
        userID: UUID,
        userFilter: String,
        status: SupabaseActivityWindowStatus?,
        from: Date?,
        to: Date?,
        limit: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "\(userFilter).\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "start_at.asc"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit, upperBound: 500))")
        ]
        if let status {
            queryItems.append(URLQueryItem(name: "status", value: "eq.\(status.rawValue)"))
        }
        if let from {
            queryItems.append(URLQueryItem(name: "end_at", value: "gt.\(dateFormatter.string(from: from))"))
        }
        if let to {
            queryItems.append(URLQueryItem(name: "start_at", value: "lt.\(dateFormatter.string(from: to))"))
        }
        return queryItems
    }

    private func ownedActivityWindowQueryItems(userID: UUID, activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(activityWindowID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    private func otherEnabledActivityWindowQueryItems(userID: UUID, keeping activityWindowID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(SupabaseActivityWindowStatus.enabled.rawValue)"),
            URLQueryItem(name: "id", value: "neq.\(activityWindowID.uuidString.lowercased())")
        ]
    }

    private func localModeSettingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func validateCreateInput(_ input: SupabaseActivityWindowCreateInput) throws {
        try validateVenue(input.venue)
        guard input.startAt < input.endAt else {
            throw SupabaseActivityWindowClientError.invalidTimeRange
        }
        try validateRadius(input.radiusMeters)
        if let center = input.center {
            try validateCoordinate(center)
        }
        try validateEventName(input.eventName)
        try validateNote(input.note)
    }

    private func validateVenue(_ venue: String) throws {
        let normalized = SupabaseTextNormalizer.trimmed(venue)
        guard !normalized.isEmpty, normalized.count <= 100 else {
            throw SupabaseActivityWindowClientError.invalidVenue
        }
    }

    private func validateRadius(_ radiusMeters: Int) throws {
        guard (50...5_000).contains(radiusMeters) else {
            throw SupabaseActivityWindowClientError.invalidRadius
        }
    }

    private func validateCoordinate(_ coordinate: SupabaseActivityWindowCoordinate) throws {
        guard (-90...90).contains(coordinate.latitude),
              (-180...180).contains(coordinate.longitude)
        else {
            throw SupabaseActivityWindowClientError.invalidCoordinate
        }
    }

    private func validateEventName(_ eventName: String?) throws {
        guard SupabaseTextNormalizer.optional(eventName)?.count ?? 0 <= 100 else {
            throw SupabaseActivityWindowClientError.invalidEventName
        }
    }

    private func validateNote(_ note: String?) throws {
        guard SupabaseTextNormalizer.optional(note)?.count ?? 0 <= 200 else {
            throw SupabaseActivityWindowClientError.invalidNote
        }
    }

    private func boundedLimit(_ limit: Int, upperBound: Int) -> Int {
        max(1, min(limit, upperBound))
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
