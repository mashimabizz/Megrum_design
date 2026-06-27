import Foundation
import MegrumCore
import MegrumData

public protocol MegrumAuthRepository: Sendable {
    var isConfigured: Bool { get }
    var oauthCallbackScheme: String? { get }

    func signIn(email: String, password: String) async throws -> AuthSession
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession
    func googleOAuthAuthorizeURL() throws -> URL
    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession
    func sendPasswordReset(email: String) async throws
    func signOut(session: AuthSession) async throws
    func refreshSession(_ session: AuthSession) async throws -> AuthSession
    func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession?
}

public extension MegrumAuthRepository {
    var oauthCallbackScheme: String? { nil }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func googleOAuthAuthorizeURL() throws -> URL {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendPasswordReset(email: String) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        session
    }

    func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession? {
        nil
    }
}

public struct PreviewMegrumAuthRepository: MegrumAuthRepository {
    public var isConfigured: Bool { false }
    public var oauthCallbackScheme: String? { "megrum-preview" }

    public init() {}

    public func signIn(email: String, password: String) async throws -> AuthSession {
        Self.previewSession(email: email)
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        Self.previewSession(email: "apple-preview@megrum.jp")
    }

    public func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        Self.previewSession(email: input.email)
    }

    public func sendPasswordReset(email: String) async throws {}

    public func signOut(session: AuthSession) async throws {}

    public func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        session
    }

    public static func previewSession(email: String = "preview@megrum.jp") -> AuthSession {
        AuthSession(
            accessToken: "preview_access_token",
            refreshToken: "preview_refresh_token",
            user: AuthUser(
                id: UUID(uuidString: "2A9A2FA0-8D06-44C5-8EDF-4BA69DD6E42A")!,
                email: email,
                createdAt: Date(timeIntervalSince1970: 1_780_000_000)
            )
        )
    }
}

public struct SupabaseMegrumAuthRepository: MegrumAuthRepository {
    public var isConfigured: Bool { true }
    public var oauthCallbackScheme: String? { oauthCallbackSchemeValue }

    private let client: SupabaseAuthClient
    private let accountClient: SupabaseAccountClient?
    private let emailRedirectTo: URL?
    private let oauthAuthorizeURL: URL?
    private let oauthRedirectTo: URL?
    private let oauthCallbackSchemeValue: String?

    public init(
        client: SupabaseAuthClient,
        accountClient: SupabaseAccountClient? = nil,
        emailRedirectTo: URL? = nil,
        oauthAuthorizeURL: URL? = nil
    ) {
        self.client = client
        self.accountClient = accountClient
        self.emailRedirectTo = emailRedirectTo
        self.oauthAuthorizeURL = oauthAuthorizeURL
        let oauthCallbackScheme = Self.callbackScheme(from: emailRedirectTo) ?? "megrum-preview"
        self.oauthCallbackSchemeValue = oauthCallbackScheme
        self.oauthRedirectTo = Self.oauthRedirectURL(callbackScheme: oauthCallbackScheme)
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        try await client.signIn(email: email, password: password)
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        try await client.signInWithIDToken(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
        )
    }

    public func googleOAuthAuthorizeURL() throws -> URL {
        if let oauthAuthorizeURL {
            return try Self.hostedOAuthAuthorizeURL(
                baseURL: oauthAuthorizeURL,
                provider: .google,
                redirectTo: oauthRedirectTo,
                scopes: ["email", "profile"]
            )
        }
        return try client.makeOAuthAuthorizeURL(
            provider: .google,
            redirectTo: oauthRedirectTo,
            scopes: ["email", "profile"]
        )
    }

    public func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        let session = try await client.signUp(
            email: input.email,
            password: input.password,
            metadata: SupabaseAuthProfileMetadata(
                handle: input.handle,
                displayName: input.displayName ?? input.handle
            ),
            emailRedirectTo: emailRedirectTo
        )
        _ = try await accountClient?.ensureUserProfile(
            session: session,
            handle: input.handle,
            displayName: input.displayName
        )
        return session
    }

    public func sendPasswordReset(email: String) async throws {
        try await client.sendPasswordReset(email: email, emailRedirectTo: emailRedirectTo)
    }

    public func signOut(session: AuthSession) async throws {
        try await client.signOut(accessToken: session.accessToken)
    }

    public func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        let refreshToken = session.refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let refreshToken, !refreshToken.isEmpty else {
            return session
        }
        return try await client.refreshSession(refreshToken: refreshToken)
    }

    public func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession? {
        try await client.session(fromRedirectURL: url)
    }

    private static func callbackScheme(from redirectURL: URL?) -> String? {
        guard
            let redirectURL,
            let components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false),
            let scheme = components.queryItems?.first(where: { $0.name == "scheme" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
            !scheme.isEmpty
        else {
            return nil
        }
        return scheme
    }

    private static func oauthRedirectURL(callbackScheme: String) -> URL? {
        let scheme = callbackScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scheme.isEmpty else {
            return nil
        }
        return URL(string: "\(scheme)://auth/callback")
    }

    private static func hostedOAuthAuthorizeURL(
        baseURL: URL,
        provider: SupabaseOAuthProvider,
        redirectTo: URL?,
        scopes: [String]
    ) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "provider", value: provider.rawValue))
        if let redirectTo {
            queryItems.append(URLQueryItem(name: "redirect_to", value: redirectTo.absoluteString))
        }
        let normalizedScopes = scopes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !normalizedScopes.isEmpty {
            queryItems.append(URLQueryItem(name: "scopes", value: normalizedScopes.joined(separator: " ")))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.invalidURL
        }
        return url
    }
}
