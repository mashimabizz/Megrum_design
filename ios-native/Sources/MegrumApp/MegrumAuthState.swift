import Foundation
import MegrumCore
import MegrumData

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
                fullName: fullName.nilIfBlank
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
}
