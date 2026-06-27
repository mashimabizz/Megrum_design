import MegrumCore

enum AccountSetupSessionPolicy {
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
        return accountStatus?.requiresSetup == true
    }
}
