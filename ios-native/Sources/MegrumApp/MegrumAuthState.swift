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
    public static let invalidEmailMessage = "メールアドレスの形式を確認してください"
    public static let missingPasswordMessage = "パスワードを入力してください"
    public static let shortPasswordMessage = "パスワードは8文字以上で入力してください"
    public static let invalidHandleMessage = "ユーザーIDは3〜24文字の英数字と_で入力してください"

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
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        return labels.count >= 2 && labels.allSatisfy { !$0.isEmpty }
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

    public static func signInValidationMessage(email: String, password: String) -> String? {
        guard isValidEmail(email) else {
            return invalidEmailMessage
        }
        guard isValidSignInPassword(password) else {
            return missingPasswordMessage
        }
        return nil
    }

    public static func signUpValidationMessage(email: String, password: String, handle: String?) -> String? {
        guard isValidEmail(email) else {
            return invalidEmailMessage
        }
        guard isValidSignUpPassword(password) else {
            return shortPasswordMessage
        }
        guard isValidHandle(handle) else {
            return invalidHandleMessage
        }
        return nil
    }

    public static func passwordResetValidationMessage(email: String) -> String? {
        isValidEmail(email) ? nil : invalidEmailMessage
    }
}

private enum MegrumAuthStateError: Error {
    case timedOut
}

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
    private let oauthCallbackSchemeValue: String?

    public init(
        client: SupabaseAuthClient,
        accountClient: SupabaseAccountClient? = nil,
        emailRedirectTo: URL? = nil
    ) {
        self.client = client
        self.accountClient = accountClient
        self.emailRedirectTo = emailRedirectTo
        self.oauthCallbackSchemeValue = Self.callbackScheme(from: emailRedirectTo) ?? "megrum-preview"
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
        try client.makeOAuthAuthorizeURL(
            provider: .google,
            redirectTo: emailRedirectTo,
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
}

@MainActor
public final class MegrumAuthState: ObservableObject {
    @Published public private(set) var session: AuthSession?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var successMessage: String?
    @Published public private(set) var passwordResetMessage: String?

    public let isConfigured: Bool
    private let repository: any MegrumAuthRepository
    private let sessionStore: any AuthSessionStore
    private let authActionTimeoutNanoseconds: UInt64
    private let signOutTimeoutNanoseconds: UInt64

    public init(
        repository: any MegrumAuthRepository,
        sessionStore: any AuthSessionStore = InMemoryAuthSessionStore(),
        initialSession: AuthSession? = nil,
        authActionTimeoutNanoseconds: UInt64 = 20_000_000_000,
        signOutTimeoutNanoseconds: UInt64 = 8_000_000_000
    ) {
        self.repository = repository
        self.sessionStore = sessionStore
        self.isConfigured = repository.isConfigured
        self.authActionTimeoutNanoseconds = authActionTimeoutNanoseconds
        self.signOutTimeoutNanoseconds = signOutTimeoutNanoseconds
        if let initialSession {
            self.session = initialSession
        } else {
            do {
                self.session = try sessionStore.load()
            } catch {
                self.session = nil
                try? sessionStore.clear()
            }
        }
    }

    public var isAuthenticated: Bool {
        session != nil
    }

    public var oauthCallbackScheme: String? {
        repository.oauthCallbackScheme
    }

    public func clearFeedback() {
        errorMessage = nil
        successMessage = nil
        passwordResetMessage = nil
    }

    public func signIn(email: String, password: String) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        if let validationMessage = MegrumAuthInputValidator.signInValidationMessage(
            email: trimmedEmail,
            password: password
        ) {
            errorMessage = validationMessage
            successMessage = nil
            passwordResetMessage = nil
            return
        }

        let repository = repository
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
            successMessage = nil
            passwordResetMessage = nil
            return
        }

        let repository = repository
        await runAuthAction {
            try await repository.signInWithApple(
                idToken: trimmedIDToken,
                nonce: trimmedNonce,
                fullName: fullName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            )
        }
    }

    public func googleOAuthAuthorizeURL() throws -> URL {
        guard isConfigured else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return try repository.googleOAuthAuthorizeURL()
    }

    public func signUp(email: String, password: String, handle: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail) else {
            errorMessage = "有効なメールアドレスを入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidSignUpPassword(password) else {
            errorMessage = "パスワードは8文字以上で入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidHandle(handle) else {
            errorMessage = "ユーザーIDは3〜24文字の英数字と_で入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        let trimmedHandle = MegrumAuthInputValidator.normalizedHandle(handle)

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            let nextSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.signUp(
                    AuthSignUpInput(
                        email: trimmedEmail,
                        password: password,
                        handle: trimmedHandle
                    )
                )
            }
            activateSession(nextSession)
        } catch {
            if isLikelyEmailConfirmationRequiredAfterSignUp(error) {
                successMessage = "確認メールを送信しました。メール内のリンクで認証を完了してからログインしてください"
                return
            }
            errorMessage = normalizedMessage(from: error)
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
            successMessage = nil
            passwordResetMessage = nil
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.sendPasswordReset(email: trimmedEmail)
            }
            passwordResetMessage = "再設定メールを送信しました。受信メールを確認してください"
            successMessage = passwordResetMessage
            return true
        } catch {
            errorMessage = normalizedMessage(from: error)
            return false
        }
    }

    public func enterPreview() {
        session = PreviewMegrumAuthRepository.previewSession()
        clearFeedback()
    }

    @discardableResult
    public func refreshSessionIfNeeded(now: Date = .now, leeway: TimeInterval = 300) async -> Bool {
        guard let currentSession = session else {
            return false
        }
        guard currentSession.shouldRefresh(now: now, leeway: leeway) else {
            return true
        }
        guard !isLoading else {
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            let refreshedSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.refreshSession(currentSession)
            }
            activateSession(refreshedSession)
            return true
        } catch {
            errorMessage = "ログイン情報を更新できませんでした。接続を確認して再読み込みしてください"
            return false
        }
    }

    @discardableResult
    public func handleOpenURL(_ url: URL) async -> Bool {
        guard !isLoading else {
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            guard let nextSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds, operation: {
                try await repository.restoreSession(fromRedirectURL: url)
            }) else {
                return false
            }
            activateSession(nextSession)
            return true
        } catch {
            errorMessage = normalizedMessage(from: error)
            return false
        }
    }

    public func signOut() async {
        let currentSession = session
        isLoading = true
        clearFeedback()
        session = nil

        do {
            try sessionStore.clear()
            successMessage = "ログアウトしました"
        } catch {
            errorMessage = "端末からログアウトしましたが、保存情報の削除に失敗しました。アプリを再起動してからもう一度お試しください"
        }
        isLoading = false

        guard let currentSession else {
            return
        }

        let repository = repository
        do {
            try await withAuthTimeout(nanoseconds: signOutTimeoutNanoseconds) {
                try await repository.signOut(session: currentSession)
            }
        } catch {
            // Remote sign-out must not trap the user in the authenticated shell.
        }
    }

    private func runAuthAction(_ action: @escaping @Sendable () async throws -> AuthSession) async {
        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        do {
            let nextSession = try await withAuthTimeout(
                nanoseconds: authActionTimeoutNanoseconds,
                operation: action
            )
            activateSession(nextSession)
        } catch {
            errorMessage = normalizedMessage(from: error)
        }
    }

    private func activateSession(_ nextSession: AuthSession) {
        session = nextSession
        do {
            try sessionStore.save(nextSession)
        } catch {
            successMessage = "ログインしました。ただし保存に失敗したため、次回起動時は再ログインが必要な場合があります"
        }
    }

    private func withAuthTimeout<T: Sendable>(
        nanoseconds: UInt64,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds)
                throw MegrumAuthStateError.timedOut
            }

            guard let result = try await group.next() else {
                throw MegrumAuthStateError.timedOut
            }
            group.cancelAll()
            return result
        }
    }

    private func isLikelyEmailConfirmationRequiredAfterSignUp(_ error: Error) -> Bool {
        if case let DecodingError.keyNotFound(key, _) = error, key.stringValue == "access_token" {
            return true
        }
        if case let SupabaseAuthError.unexpectedStatus(_, message) = error,
           let message,
           message.localizedCaseInsensitiveContains("confirm") {
            return true
        }
        return false
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
        if case MegrumAuthStateError.timedOut = error {
            return "通信に時間がかかっています。接続を確認してもう一度お試しください"
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
            sessionStore: InMemoryAuthSessionStore()
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
