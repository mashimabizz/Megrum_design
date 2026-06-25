import Foundation

extension MegrumAppState {
    @discardableResult
    public func loadHomeLocalModeSettings(
        fallback: HomeLocalActivitySettings? = nil,
        now: Date = .now
    ) async -> HomeLocalActivitySettings? {
        guard !isLoadingHomeLocalModeSettings else {
            return homeLocalModeSettings ?? fallback
        }

        isLoadingHomeLocalModeSettings = true
        errorMessage = nil
        defer {
            isLoadingHomeLocalModeSettings = false
        }

        do {
            if let loaded = try await repository.loadHomeLocalModeSettings(now: now) {
                let normalized = loaded.normalizedForPersistence(now: now)
                homeLocalModeSettings = normalized
                return normalized
            }
            if homeLocalModeSettings == nil {
                homeLocalModeSettings = fallback?.normalizedForPersistence(now: now)
            }
            return homeLocalModeSettings ?? fallback
        } catch {
            if homeLocalModeSettings == nil {
                homeLocalModeSettings = fallback?.normalizedForPersistence(now: now)
            }
            errorMessage = "現地交換モードを読み込めませんでした"
            return homeLocalModeSettings ?? fallback
        }
    }

    @discardableResult
    public func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date = .now
    ) async -> HomeLocalActivitySettings? {
        guard !isSavingHomeLocalModeSettings else {
            return nil
        }

        let previous = homeLocalModeSettings
        let prepared = settings.normalizedForPersistence(
            now: now,
            fallbackActivityWindowID: previous?.activityWindowID
        )
        guard !prepared.isEnabled || !prepared.normalizedVenue.isEmpty else {
            errorMessage = "場所を入力してください"
            return nil
        }

        homeLocalModeSettings = prepared
        isSavingHomeLocalModeSettings = true
        errorMessage = nil
        do {
            let saved = try await repository.saveHomeLocalModeSettings(prepared, now: now)
            let normalized = saved.normalizedForPersistence(now: now, fallbackActivityWindowID: prepared.activityWindowID)
            homeLocalModeSettings = normalized
            isSavingHomeLocalModeSettings = false
            return normalized
        } catch {
            homeLocalModeSettings = previous
            errorMessage = "現地交換モードを保存できませんでした"
            isSavingHomeLocalModeSettings = false
            return nil
        }
    }
}
