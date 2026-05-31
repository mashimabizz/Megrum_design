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

public enum MegrumAuthInputValidator {
    public static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func isValidEmail(_ email: String) -> Bool {
        let value = normalizedEmail(email)
        guard !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return false
        }

        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            return false
        }

        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    public static func isValidSignInPassword(_ password: String) -> Bool {
        !password.isEmpty
    }

    public static func isValidSignUpPassword(_ password: String) -> Bool {
        password.count >= 8 && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public static func normalizedHandle(_ handle: String?) -> String? {
        handle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public static func isValidHandle(_ handle: String?) -> Bool {
        guard let handle = normalizedHandle(handle) else {
            return true
        }
        guard (3...24).contains(handle.count) else {
            return false
        }
        return handle.range(of: #"^[A-Za-z0-9_]+$"#, options: .regularExpression) != nil
    }
}

public protocol MegrumAuthRepository: Sendable {
    var isConfigured: Bool { get }

    func signIn(email: String, password: String) async throws -> AuthSession
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession
    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession
    func sendPasswordReset(email: String) async throws
    func signOut(session: AuthSession) async throws
    func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession?
}

public extension MegrumAuthRepository {
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendPasswordReset(email: String) async throws {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession? {
        nil
    }
}

public struct PreviewMegrumAuthRepository: MegrumAuthRepository {
    public var isConfigured: Bool { false }

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

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        try await client.signInWithIDToken(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
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

    public func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession? {
        try await client.session(fromRedirectURL: url)
    }
}

@MainActor
public final class MegrumAuthState: ObservableObject {
    @Published public private(set) var session: AuthSession?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var passwordResetMessage: String?

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
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail),
              MegrumAuthInputValidator.isValidSignInPassword(password) else {
            errorMessage = "有効なメールアドレスとパスワードを入力してください"
            passwordResetMessage = nil
            return
        }

        await runAuthAction {
            try await repository.signIn(email: trimmedEmail, password: password)
        }
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedIDToken = idToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNonce = nonce.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIDToken.isEmpty, !trimmedNonce.isEmpty else {
            errorMessage = "Appleログイン情報を取得できませんでした。もう一度お試しください"
            passwordResetMessage = nil
            return
        }

        await runAuthAction {
            try await repository.signInWithApple(
                idToken: trimmedIDToken,
                nonce: trimmedNonce,
                fullName: fullName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            )
        }
    }

    public func signUp(email: String, password: String, handle: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail) else {
            errorMessage = "有効なメールアドレスを入力してください"
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidSignUpPassword(password) else {
            errorMessage = "パスワードは8文字以上で入力してください"
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidHandle(handle) else {
            errorMessage = "ユーザーIDは3〜24文字の英数字と_で入力してください"
            passwordResetMessage = nil
            return
        }
        let trimmedHandle = MegrumAuthInputValidator.normalizedHandle(handle)

        await runAuthAction {
            try await repository.signUp(
                AuthSignUpInput(
                    email: trimmedEmail,
                    password: password,
                    handle: trimmedHandle
                )
            )
        }
    }

    @discardableResult
    public func sendPasswordReset(email: String) async -> Bool {
        guard !isLoading else {
            return false
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail) else {
            errorMessage = "有効なメールアドレスを入力してください"
            passwordResetMessage = nil
            return false
        }

        isLoading = true
        errorMessage = nil
        passwordResetMessage = nil
        defer {
            isLoading = false
        }

        do {
            try await repository.sendPasswordReset(email: trimmedEmail)
            passwordResetMessage = "再設定メールを送信しました。受信メールを確認してください"
            return true
        } catch {
            errorMessage = normalizedMessage(from: error)
            return false
        }
    }

    public func enterPreview() {
        session = PreviewMegrumAuthRepository.previewSession()
        errorMessage = nil
        passwordResetMessage = nil
    }

    @discardableResult
    public func handleOpenURL(_ url: URL) async -> Bool {
        guard !isLoading else {
            return false
        }

        isLoading = true
        errorMessage = nil
        passwordResetMessage = nil
        defer {
            isLoading = false
        }

        do {
            guard let nextSession = try await repository.restoreSession(fromRedirectURL: url) else {
                return false
            }
            try sessionStore.save(nextSession)
            session = nextSession
            return true
        } catch {
            errorMessage = normalizedMessage(from: error)
            return false
        }
    }

    public func signOut() async {
        guard let session else {
            return
        }
        isLoading = true
        errorMessage = nil
        passwordResetMessage = nil
        defer {
            isLoading = false
        }

        do {
            try await repository.signOut(session: session)
            try sessionStore.clear()
            self.session = isConfigured ? nil : PreviewMegrumAuthRepository.previewSession()
        } catch {
            errorMessage = normalizedMessage(from: error)
        }
    }

    private func runAuthAction(_ action: () async throws -> AuthSession) async {
        isLoading = true
        errorMessage = nil
        passwordResetMessage = nil
        defer {
            isLoading = false
        }

        do {
            let nextSession = try await action()
            try sessionStore.save(nextSession)
            session = nextSession
        } catch {
            errorMessage = normalizedMessage(from: error)
        }
    }

    private func normalizedMessage(from error: Error) -> String {
        if case let SupabaseAuthError.unexpectedStatus(_, message) = error, let message {
            if message.contains("Invalid login credentials") {
                return "メールアドレスまたはパスワードが正しくありません"
            }
            if message.contains("Email not confirmed") {
                return "メール認証が完了していません。受信メールを確認してください"
            }
            if message.localizedCaseInsensitiveContains("already registered") {
                return "このメールアドレスはすでに登録されています"
            }
            if message.localizedCaseInsensitiveContains("invalid email")
                || message.localizedCaseInsensitiveContains("validate email") {
                return "有効なメールアドレスを入力してください"
            }
            if message.localizedCaseInsensitiveContains("password")
                && message.localizedCaseInsensitiveContains("at least") {
                return "パスワードは8文字以上で入力してください"
            }
            if message.localizedCaseInsensitiveContains("rate limit")
                || message.localizedCaseInsensitiveContains("security purposes") {
                return "送信間隔が短すぎます。しばらく待ってから再度お試しください"
            }
            return message
        }
        if case MegrumRepositoryError.unsupportedMutation = error {
            return "このログイン方法はまだ利用できません"
        }
        return "認証に失敗しました。時間をおいてもう一度お試しください"
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
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
        authRedirectURL(from: environment["MEGRUM_AUTH_EMAIL_REDIRECT_URL"]) ?? defaultAuthRedirectURL
    }

    private static func authRedirectURL(from infoDictionary: [String: Any]?) -> URL? {
        authRedirectURL(from: infoDictionary?["MegrumAuthEmailRedirectURL"] as? String) ?? defaultAuthRedirectURL
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
}
