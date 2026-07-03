struct SettingsPresentationState: Equatable {
    var isSigningOut = false
    var navigationPath: [SettingsEssentialRoute] = []

    mutating func openRoute(_ route: SettingsEssentialRoute) {
        navigationPath.append(route)
    }

    mutating func beginSignOutIfNeeded() -> Bool {
        guard !isSigningOut else {
            return false
        }

        isSigningOut = true
        return true
    }

    mutating func finishSignOut() {
        isSigningOut = false
    }
}
