import MegrumCore

enum AccountSetupSessionPolicy {
    static func shouldReturnToLogin(
        accountStatus: AccountStatus?,
        visualQAInitialScreen: VisualQAInitialScreen?
    ) -> Bool {
        guard visualQAInitialScreen != .accountSetup else {
            return false
        }
        return accountStatus?.requiresSetup == true
    }
}
