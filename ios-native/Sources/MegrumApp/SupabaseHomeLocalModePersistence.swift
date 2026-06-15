import Foundation
import MegrumData

final class SupabaseHomeLocalModePersistence: @unchecked Sendable {
    private let activityWindowClient: SupabaseActivityWindowClient
    private let userID: UUID

    init(activityWindowClient: SupabaseActivityWindowClient, userID: UUID) {
        self.activityWindowClient = activityWindowClient
        self.userID = userID
    }

    func loadSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        async let storedSettings = activityWindowClient.loadLocalModeSettings(userID: userID)
        async let activityWindows = activityWindowClient.loadActivityWindows(userID: userID, limit: 50)

        let settings = try await storedSettings
        let windows = try await activityWindows
        let selectedWindow = SupabaseHomeLocalModeMapper.selectedWindow(
            from: windows,
            settings: settings,
            now: now
        )

        if settings == nil, selectedWindow == nil {
            return nil
        }
        return SupabaseHomeLocalModeMapper.settings(from: settings, activityWindow: selectedWindow)
    }

    func saveSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let prepared = settings.normalizedForPersistence(now: now)
        if prepared.isEnabled {
            return try await saveEnabledSettings(prepared, now: now)
        }
        return try await saveDisabledSettings(prepared, now: now)
    }

    private func saveEnabledSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let startAt = settings.startedAt ?? now
        let endAt = settings.endDate(now: now)
        let existingActivityWindowID = try await existingActivityWindowID(for: settings, now: now)
        let activityWindow: SupabaseActivityWindow

        if let existingActivityWindowID,
           let updated = try await activityWindowClient.updateActivityWindow(
            userID: userID,
            activityWindowID: existingActivityWindowID,
            input: Self.enabledActivityWindowUpdateInput(
                settings: settings,
                startAt: startAt,
                endAt: endAt
            )
           ) {
            activityWindow = updated
        } else {
            activityWindow = try await activityWindowClient.createActivityWindow(
                userID: userID,
                input: Self.enabledActivityWindowCreateInput(
                    settings: settings,
                    startAt: startAt,
                    endAt: endAt
                )
            )
        }

        _ = try await activityWindowClient.disableOtherEnabledActivityWindows(
            userID: userID,
            keeping: activityWindow.id
        )
        _ = try await activityWindowClient.upsertLocalModeSettings(
            userID: userID,
            input: Self.localModeUpsertInput(
                enabled: true,
                activityWindowID: activityWindow.id,
                settings: settings
            )
        )

        return SupabaseHomeLocalModeMapper.makeSettings(
            enabled: true,
            activityWindowID: activityWindow.id,
            radiusMeters: settings.normalizedRadiusMeters,
            selectedCarryingIDs: SupabaseHomeLocalModeMapper.sortedIDs(settings.selectedCarryingIDs),
            coordinate: activityWindow.center ?? SupabaseHomeLocalModeMapper.supabaseCoordinate(from: settings.coordinate),
            activityWindow: activityWindow
        )
    }

    private func saveDisabledSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        let existingActivityWindowID = try await existingActivityWindowID(for: settings, now: now)
        var disabledWindow: SupabaseActivityWindow?

        if let existingActivityWindowID {
            disabledWindow = try await activityWindowClient.updateActivityWindow(
                userID: userID,
                activityWindowID: existingActivityWindowID,
                input: SupabaseActivityWindowUpdateInput(status: .disabled)
            )
        }

        _ = try await activityWindowClient.upsertLocalModeSettings(
            userID: userID,
            input: Self.localModeUpsertInput(
                enabled: false,
                activityWindowID: existingActivityWindowID,
                settings: settings
            )
        )

        if let disabledWindow {
            return SupabaseHomeLocalModeMapper.makeSettings(
                enabled: false,
                activityWindowID: existingActivityWindowID,
                radiusMeters: settings.normalizedRadiusMeters,
                selectedCarryingIDs: SupabaseHomeLocalModeMapper.sortedIDs(settings.selectedCarryingIDs),
                coordinate: disabledWindow.center ?? SupabaseHomeLocalModeMapper.supabaseCoordinate(from: settings.coordinate),
                activityWindow: disabledWindow
            )
        }

        return Self.disabledFallbackSettings(
            existingActivityWindowID: existingActivityWindowID,
            settings: settings
        )
    }

    private func existingActivityWindowID(
        for settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> UUID? {
        if let activityWindowID = settings.activityWindowID {
            return activityWindowID
        }
        return try await loadSettings(now: now)?.activityWindowID
    }

    static func enabledActivityWindowUpdateInput(
        settings: HomeLocalActivitySettings,
        startAt: Date,
        endAt: Date
    ) -> SupabaseActivityWindowUpdateInput {
        SupabaseActivityWindowUpdateInput(
            venue: settings.normalizedVenue,
            center: SupabaseHomeLocalModeMapper.supabaseCoordinate(from: settings.coordinate),
            clearsCenter: settings.coordinate == nil,
            radiusMeters: settings.normalizedRadiusMeters,
            clearsEventName: true,
            eventless: true,
            startAt: startAt,
            endAt: endAt,
            clearsNote: true,
            status: .enabled
        )
    }

    static func enabledActivityWindowCreateInput(
        settings: HomeLocalActivitySettings,
        startAt: Date,
        endAt: Date
    ) -> SupabaseActivityWindowCreateInput {
        SupabaseActivityWindowCreateInput(
            venue: settings.normalizedVenue,
            center: SupabaseHomeLocalModeMapper.supabaseCoordinate(from: settings.coordinate),
            radiusMeters: settings.normalizedRadiusMeters,
            eventless: true,
            startAt: startAt,
            endAt: endAt,
            status: .enabled
        )
    }

    static func localModeUpsertInput(
        enabled: Bool,
        activityWindowID: UUID?,
        settings: HomeLocalActivitySettings
    ) -> SupabaseLocalModeSettingsUpsertInput {
        SupabaseLocalModeSettingsUpsertInput(
            enabled: enabled,
            activityWindowID: activityWindowID,
            radiusMeters: settings.normalizedRadiusMeters,
            selectedCarryingIDs: SupabaseHomeLocalModeMapper.sortedIDs(settings.selectedCarryingIDs),
            selectedWishIDs: [],
            lastLocation: SupabaseHomeLocalModeMapper.supabaseCoordinate(from: settings.coordinate),
            clearsLastLocation: settings.coordinate == nil
        )
    }

    static func disabledFallbackSettings(
        existingActivityWindowID: UUID?,
        settings: HomeLocalActivitySettings
    ) -> HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: existingActivityWindowID,
            isEnabled: false,
            venue: settings.normalizedVenue,
            coordinate: settings.coordinate,
            startedAt: settings.startedAt,
            durationMinutes: settings.normalizedDurationMinutes,
            radiusMeters: settings.normalizedRadiusMeters,
            selectedCarryingIDs: settings.selectedCarryingIDs
        )
    }
}
