import Foundation
import MegrumData

enum SupabaseHomeLocalModeMapper {
    static func selectedWindow(
        from windows: [SupabaseActivityWindow],
        settings: SupabaseLocalModeSettings?,
        now: Date
    ) -> SupabaseActivityWindow? {
        if let activityWindowID = settings?.activityWindowID,
           let window = windows.first(where: { $0.id == activityWindowID }) {
            return window
        }
        return windows
            .filter { $0.status == .enabled && $0.endAt >= now }
            .sorted { $0.startAt < $1.startAt }
            .first
    }

    static func settings(
        from settings: SupabaseLocalModeSettings?,
        activityWindow: SupabaseActivityWindow?
    ) -> HomeLocalActivitySettings {
        makeSettings(
            enabled: settings?.enabled,
            activityWindowID: settings?.activityWindowID,
            radiusMeters: settings?.radiusMeters,
            selectedCarryingIDs: settings?.selectedCarryingIDs ?? [],
            coordinate: settings?.lastLocation ?? activityWindow?.center,
            activityWindow: activityWindow
        )
    }

    static func makeSettings(
        enabled: Bool?,
        activityWindowID: UUID?,
        radiusMeters: Int?,
        selectedCarryingIDs: [UUID],
        coordinate: SupabaseActivityWindowCoordinate? = nil,
        activityWindow: SupabaseActivityWindow?
    ) -> HomeLocalActivitySettings {
        let durationMinutes = activityWindow.map { window in
            max(30, Int(window.endAt.timeIntervalSince(window.startAt) / 60))
        } ?? HomeLocalActivitySettings.defaultDurationMinutes
        let activityWindowIsEnabled = activityWindow?.status == .enabled

        return HomeLocalActivitySettings(
            activityWindowID: activityWindowID ?? activityWindow?.id,
            isEnabled: (enabled ?? activityWindowIsEnabled) && activityWindowIsEnabled,
            venue: activityWindow?.venue ?? "",
            coordinate: megrumCoordinate(from: coordinate ?? activityWindow?.center),
            startedAt: activityWindow?.startAt,
            durationMinutes: HomeLocalActivitySettings.normalizedDurationMinutes(durationMinutes),
            radiusMeters: HomeLocalActivitySettings.normalizedRadiusMeters(
                radiusMeters ?? activityWindow?.radiusMeters ?? HomeLocalActivitySettings.defaultRadiusMeters
            ),
            selectedCarryingIDs: Set(selectedCarryingIDs)
        )
    }

    static func supabaseCoordinate(from coordinate: MegrumLocationCoordinate?) -> SupabaseActivityWindowCoordinate? {
        guard let coordinate else {
            return nil
        }
        return SupabaseActivityWindowCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func megrumCoordinate(from coordinate: SupabaseActivityWindowCoordinate?) -> MegrumLocationCoordinate? {
        guard let coordinate else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func sortedIDs(_ ids: Set<UUID>) -> [UUID] {
        ids.sorted { $0.uuidString < $1.uuidString }
    }
}
