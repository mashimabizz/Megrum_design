import Foundation

public final class SupabaseActivityWindowClient: @unchecked Sendable {
    let client: SupabaseRESTClient
    let encoder: JSONEncoder
    let dateFormatter: ISO8601DateFormatter

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
}
