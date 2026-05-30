import Foundation
import MegrumCore
import MegrumData

public struct AuthSignUpInput: Equatable, Sendable {
    public var email: String
    public var password: String
    public var handle: String?
    public var displayName: String?

    public init(email: String, password: String, handle: String? = nil, displayName: String? = nil) {
        self.email = email
        self.password = password
        self.handle = handle
        self.displayName = displayName
    }
}

public protocol MegrumAuthRepository: Sendable {
    var isConfigured: Bool { get }

    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession
    func signOut(session: AuthSession) async throws
}

public struct PreviewMegrumAuthRepository: MegrumAuthRepository {
    public var isConfigured: Bool { false }

    public init() {}

    public func signIn(email: String, password: String) async throws -> AuthSession {
        Self.previewSession(email: email)
    }

    public func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        Self.previewSession(email: input.email)
    }

    public func signOut(session: AuthSession) async throws {}

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

    private let client: SupabaseAuthClient
    private let accountClient: SupabaseAccountClient?
    private let emailRedirectTo: URL?

    public init(
        client: SupabaseAuthClient,
        accountClient: SupabaseAccountClient? = nil,
        emailRedirectTo: URL? = nil
    ) {
        self.client = client
        self.accountClient = accountClient
        self.emailRedirectTo = emailRedirectTo
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        try await client.signIn(email: email, password: password)
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

    public func signOut(session: AuthSession) async throws {
        try await client.signOut(accessToken: session.accessToken)
    }
}

@MainActor
public final class MegrumAuthState: ObservableObject {
    @Published public private(set) var session: AuthSession?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    public let isConfigured: Bool
    private let repository: any MegrumAuthRepository
    private let sessionStore: any AuthSessionStore

    public init(
        repository: any MegrumAuthRepository,
        sessionStore: any AuthSessionStore = InMemoryAuthSessionStore(),
        initialSession: AuthSession? = nil
    ) {
        self.repository = repository
        self.sessionStore = sessionStore
        self.isConfigured = repository.isConfigured
        self.session = initialSession ?? (try? sessionStore.load())
    }

    public var isAuthenticated: Bool {
        session != nil
    }

    public func signIn(email: String, password: String) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        await runAuthAction {
            try await repository.signIn(email: trimmedEmail, password: password)
        }
    }

    public func signUp(email: String, password: String, handle: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 8 else {
            errorMessage = "メールアドレスと8文字以上のパスワードを入力してください"
            return
        }

        await runAuthAction {
            try await repository.signUp(
                AuthSignUpInput(
                    email: trimmedEmail,
                    password: password,
                    handle: handle?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }
    }

    public func enterPreview() {
        session = PreviewMegrumAuthRepository.previewSession()
        errorMessage = nil
    }

    public func signOut() async {
        guard let session else {
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            try await repository.signOut(session: session)
            try sessionStore.clear()
            self.session = isConfigured ? nil : PreviewMegrumAuthRepository.previewSession()
        } catch {
            errorMessage = normalizedMessage(from: error)
        }

        isLoading = false
    }

    private func runAuthAction(_ action: () async throws -> AuthSession) async {
        isLoading = true
        errorMessage = nil

        do {
            let nextSession = try await action()
            try sessionStore.save(nextSession)
            session = nextSession
        } catch {
            errorMessage = normalizedMessage(from: error)
        }

        isLoading = false
    }

    private func normalizedMessage(from error: Error) -> String {
        if case let SupabaseAuthError.unexpectedStatus(_, message) = error, let message {
            if message.contains("Invalid login credentials") {
                return "メールアドレスまたはパスワードが正しくありません"
            }
            if message.contains("Email not confirmed") {
                return "メール認証が完了していません。受信メールを確認してください"
            }
            return message
        }
        return "認証に失敗しました。時間をおいてもう一度お試しください"
    }
}

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
        if let configuration = SupabaseConfiguration.fromEnvironment(environment) {
            return liveState(
                configuration: configuration,
                emailRedirectTo: authRedirectURL(from: environment)
            )
        }

        if let configuration = SupabaseConfiguration.fromInfoDictionary(infoDictionary) {
            return liveState(
                configuration: configuration,
                emailRedirectTo: authRedirectURL(from: infoDictionary)
            )
        }

        return MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            sessionStore: InMemoryAuthSessionStore(),
            initialSession: PreviewMegrumAuthRepository.previewSession()
        )
    }

    @MainActor
    private static func liveState(configuration: SupabaseConfiguration, emailRedirectTo: URL?) -> MegrumAuthState {
        MegrumAuthState(
            repository: SupabaseMegrumAuthRepository(
                client: SupabaseAuthClient(configuration: configuration),
                accountClient: SupabaseAccountClient(configuration: configuration),
                emailRedirectTo: emailRedirectTo
            ),
            sessionStore: KeychainAuthSessionStore()
        )
    }

    private static func authRedirectURL(from environment: [String: String]) -> URL? {
        if let value = environment["MEGRUM_AUTH_EMAIL_REDIRECT_URL"], let url = URL(string: value) {
            return url
        }
        return defaultAuthRedirectURL
    }

    private static func authRedirectURL(from infoDictionary: [String: Any]?) -> URL? {
        if let value = infoDictionary?["MegrumAuthEmailRedirectURL"] as? String, let url = URL(string: value) {
            return url
        }
        return defaultAuthRedirectURL
    }

    private static var defaultAuthRedirectURL: URL? {
        URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")
    }
}
