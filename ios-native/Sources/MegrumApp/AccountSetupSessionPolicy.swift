import MegrumCore

enum AccountSetupSessionPolicy {
    static func shouldShowAuthScreen(
        isAuthenticated: Bool,
        isReturningStoredIncompleteAccountToLogin: Bool
    ) -> Bool {
        !isAuthenticated || isReturningStoredIncompleteAccountToLogin
    }

    static func shouldReturnToLogin(
        accountStatus: AccountStatus?,
        sessionSource: MegrumAuthSessionSource,
        visualQAInitialScreen: VisualQAInitialScreen?
    ) -> Bool {
        guard visualQAInitialScreen != .accountSetup else {
            return false
        }
        guard sessionSource == .stored else {
            return false
        }
        switch accountStatus {
        case .registered?, .verified?:
            return true
        case .onboarding?, .active?, .suspended?, .deletionRequested?, .deleted?, nil:
            return false
        }
    }

    static func shouldClearReturnToLoginOverride(sessionSource: MegrumAuthSessionSource) -> Bool {
        switch sessionSource {
        case .none, .interactive:
            true
        case .initial, .stored:
            false
        }
    }
}
