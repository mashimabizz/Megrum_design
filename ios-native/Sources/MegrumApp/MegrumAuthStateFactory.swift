import Foundation
import MegrumData

public enum MegrumAuthStateFactory {
    @MainActor
    public static func makeDefault() -> MegrumAuthState {
        make(environment: ProcessInfo.processInfo.environment, infoDictionary: Bundle.main.infoDictionary)
    }

    @MainActor
    public static func make(
        environment: [String: String],
        infoDictionary: [String: Any]? = nil
    ) -> MegrumAuthState {
        if VisualQAPreviewMode.isEnabled(environment: environment) {
            if VisualQAPreviewMode.initialScreen(environment: environment)?.isAuthRoute == true {
                return MegrumAuthState(
                    repository: PreviewMegrumAuthRepository(),
                    sessionStore: InMemoryAuthSessionStore()
                )
            }
            return MegrumAuthState(
                repository: PreviewMegrumAuthRepository(),
                initialSession: PreviewMegrumAuthRepository.previewSession()
            )
        }

        if let configuration = SupabaseConfiguration.fromEnvironment(environment) {
            return liveState(
                configuration: configuration,
                emailRedirectTo: authRedirectURL(from: environment),
                oauthAuthorizeURL: oauthAuthorizeURL(from: environment)
            )
        }

        if let configuration = SupabaseConfiguration.fromInfoDictionary(infoDictionary) {
            return liveState(
                configuration: configuration,
                emailRedirectTo: authRedirectURL(from: infoDictionary),
                oauthAuthorizeURL: oauthAuthorizeURL(from: infoDictionary)
            )
        }

        return MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            sessionStore: InMemoryAuthSessionStore()
        )
    }

    @MainActor
    private static func liveState(
        configuration: SupabaseConfiguration,
        emailRedirectTo: URL?,
        oauthAuthorizeURL: URL?
    ) -> MegrumAuthState {
        MegrumAuthState(
            repository: SupabaseMegrumAuthRepository(
                client: SupabaseAuthClient(configuration: configuration),
                accountClient: SupabaseAccountClient(configuration: configuration),
                emailRedirectTo: emailRedirectTo,
                oauthAuthorizeURL: oauthAuthorizeURL
            ),
            sessionStore: KeychainAuthSessionStore()
        )
    }

    private static func authRedirectURL(from environment: [String: String]) -> URL? {
        authRedirectURL(from: environment["MEGRUM_AUTH_EMAIL_REDIRECT_URL"]) ?? defaultAuthRedirectURL
    }

    private static func oauthAuthorizeURL(from environment: [String: String]) -> URL? {
        authRedirectURL(from: environment["MEGRUM_AUTH_OAUTH_AUTHORIZE_URL"]) ?? defaultOAuthAuthorizeURL
    }

    private static func authRedirectURL(from infoDictionary: [String: Any]?) -> URL? {
        authRedirectURL(from: infoDictionary?["MegrumAuthEmailRedirectURL"] as? String) ?? defaultAuthRedirectURL
    }

    private static func oauthAuthorizeURL(from infoDictionary: [String: Any]?) -> URL? {
        authRedirectURL(from: infoDictionary?["MegrumAuthOAuthAuthorizeURL"] as? String) ?? defaultOAuthAuthorizeURL
    }

    private static func authRedirectURL(from rawValue: String?) -> URL? {
        guard
            let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty,
            !rawValue.contains("$("),
            let url = URL(string: rawValue),
            url.scheme != nil
        else {
            return nil
        }

        return url
    }

    private static var defaultAuthRedirectURL: URL? {
        URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")
    }

    private static var defaultOAuthAuthorizeURL: URL? {
        URL(string: "https://megrum.jp/auth/oauth/authorize")
    }
}
