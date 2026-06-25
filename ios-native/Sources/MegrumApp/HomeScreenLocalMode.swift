import Foundation
import MegrumCore

@MainActor
extension HomeScreen {
    var localActivitySettings: HomeLocalActivitySettings {
        localModeState?.homeLocalModeSettings ?? loadedLocalActivitySettings ?? localStorageActivitySettings
    }

    var localStorageActivitySettings: HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: UUID(uuidString: localModeActivityWindowID),
            isEnabled: localModeEnabled,
            venue: localModeVenue,
            coordinate: HomeLocalCoordinateStorageCodec.decode(
                latitudeText: localModeLatitude,
                longitudeText: localModeLongitude
            ) ?? HomeLocalLocationLabel.coordinate(in: localModeVenue),
            startedAt: localModeStartedAt > 0 ? Date(timeIntervalSince1970: localModeStartedAt) : nil,
            durationMinutes: normalizedDurationMinutes,
            radiusMeters: normalizedRadiusMeters,
            selectedCarryingIDs: HomeLocalCarryingSelectionCodec.decode(localModeSelectedCarryingIDs)
        )
    }

    var localModeState: MegrumAppState? {
        appState ?? MegrumAppState.activeInstance
    }

    var localCarryingCandidates: [HomeLocalCarryingCandidate] {
        let sourceItems = HomeLocalCarryingCandidate.sourceItems(
            inventory: localModeState?.inventory ?? [],
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
        return HomeLocalCarryingCandidate.candidates(
            from: sourceItems,
            viewerID: viewer?.id
        )
    }

    var normalizedDurationMinutes: Int {
        HomeLocalActivitySettings.normalizedDurationMinutes(localModeDurationMinutes)
    }

    var normalizedRadiusMeters: Int {
        HomeLocalActivitySettings.normalizedRadiusMeters(localModeRadiusMeters)
    }

    var homeGroomEntrySummary: HomeGroomEntrySummary? {
        guard let localModeState else {
            return nil
        }
        return HomeGroomEntrySummary(
            groomCount: localModeState.grooms.count,
            localStatus: localActivitySettings.status(),
            venue: localActivitySettings.displayVenue(fallbackPrefecture: viewer?.prefecture)
        )
    }

    var homeGroomPosts: [GroomPost] {
        localModeState?.grooms ?? []
    }

    func saveLocalActivitySettings(_ settings: HomeLocalActivitySettings) {
        let availableIDs = Set(localCarryingCandidates.map(\.id))
        let sanitized = settings
            .normalizedForPersistence(fallbackActivityWindowID: localActivitySettings.activityWindowID)
            .replacingSelectedCarryingIDs(settings.selectedCarryingIDs.intersection(availableIDs))

        loadedLocalActivitySettings = sanitized
        persistLocalActivitySettings(sanitized)

        guard let localModeState else {
            return
        }

        Task { @MainActor in
            guard let saved = await localModeState.saveHomeLocalModeSettings(sanitized) else {
                return
            }
            let persisted = saved
                .replacingSelectedCarryingIDs(saved.selectedCarryingIDs.intersection(availableIDs))
                .mergingMissingLocalCoordinate(from: sanitized)
            loadedLocalActivitySettings = persisted
            persistLocalActivitySettings(persisted)
        }
    }

    func loadLocalActivitySettings() async {
        guard let localModeState else {
            return
        }
        guard let settings = await localModeState.loadHomeLocalModeSettings(fallback: localStorageActivitySettings) else {
            return
        }
        let loaded = settings.mergingMissingLocalCoordinate(from: localStorageActivitySettings)
        loadedLocalActivitySettings = loaded
        persistLocalActivitySettings(loaded)
    }

    func persistLocalActivitySettings(_ settings: HomeLocalActivitySettings) {
        localModeActivityWindowID = settings.activityWindowID?.uuidString.lowercased() ?? ""
        localModeEnabled = settings.isEnabled
        localModeVenue = settings.venue
        localModeLatitude = HomeLocalCoordinateStorageCodec.latitudeText(settings.coordinate)
        localModeLongitude = HomeLocalCoordinateStorageCodec.longitudeText(settings.coordinate)
        localModeStartedAt = settings.startedAt?.timeIntervalSince1970 ?? localModeStartedAt
        localModeDurationMinutes = settings.durationMinutes
        localModeRadiusMeters = settings.radiusMeters
        localModeSelectedCarryingIDs = HomeLocalCarryingSelectionCodec.encode(settings.selectedCarryingIDs)
    }
}

extension HomeLocalActivitySettings {
    func mergingMissingLocalCoordinate(from fallback: HomeLocalActivitySettings) -> HomeLocalActivitySettings {
        coordinate == nil ? replacingCoordinate(fallback.coordinate) : self
    }
}
