import Foundation
import MegrumApp
import MegrumCore
import MegrumData
import XCTest

@MainActor
final class AuthScreenInputTests: XCTestCase {
    func testSignInValidationMessagesSeparateEmailAndPassword() {
        XCTAssertEqual(
            MegrumAuthInputValidator.signInValidationMessage(
                email: "michi",
                password: "password123"
            ),
            MegrumAuthInputValidator.invalidEmailMessage
        )
        XCTAssertEqual(
            MegrumAuthInputValidator.signInValidationMessage(
                email: "michi@example.com",
                password: ""
            ),
            MegrumAuthInputValidator.missingPasswordMessage
        )
        XCTAssertNil(
            MegrumAuthInputValidator.signInValidationMessage(
                email: "michi@example.com",
                password: "password123"
            )
        )
    }

    func testSignUpValidationMessagesSeparatePasswordAndHandle() {
        XCTAssertEqual(
            MegrumAuthInputValidator.signUpValidationMessage(
                email: "michi@example.com",
                password: "short",
                handle: "michi_1"
            ),
            MegrumAuthInputValidator.shortPasswordMessage
        )
        XCTAssertEqual(
            MegrumAuthInputValidator.signUpValidationMessage(
                email: "michi@example.com",
                password: "password123",
                handle: "みち"
            ),
            MegrumAuthInputValidator.invalidHandleMessage
        )
        XCTAssertNil(
            MegrumAuthInputValidator.signUpValidationMessage(
                email: " michi@example.com ",
                password: "password123",
                handle: " michi_1 "
            )
        )
    }

    func testPasswordResetUsesSharedEmailValidation() {
        XCTAssertEqual(
            MegrumAuthInputValidator.passwordResetValidationMessage(email: "michi@"),
            MegrumAuthInputValidator.invalidEmailMessage
        )
        XCTAssertNil(
            MegrumAuthInputValidator.passwordResetValidationMessage(email: "michi@example.com")
        )
    }

    func testAuthStateShowsEmailConfirmationSuccessWhenSignUpReturnsNoSession() async {
        let state = MegrumAuthState(repository: EmailConfirmationRequiredAuthRepository())

        await state.signUp(email: "michi@example.com", password: "password123", handle: "michi_1")

        XCTAssertNil(state.session)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(
            state.successMessage,
            "確認メールを送信しました。メール内のリンクで認証を完了してからログインしてください"
        )
        XCTAssertFalse(state.isLoading)
    }

    func testAuthStateCanClearFeedbackAfterModeChanges() async {
        let state = MegrumAuthState(repository: PasswordResetSuccessAuthRepository())

        let sent = await state.sendPasswordReset(email: "michi@example.com")
        XCTAssertTrue(sent)
        XCTAssertNotNil(state.passwordResetMessage)
        XCTAssertNotNil(state.successMessage)

        state.clearFeedback()

        XCTAssertNil(state.errorMessage)
        XCTAssertNil(state.passwordResetMessage)
        XCTAssertNil(state.successMessage)
    }

    func testAuthStateReportsStoredSessionLoadFailure() {
        let state = MegrumAuthState(
            repository: PasswordResetSuccessAuthRepository(),
            sessionStore: FailingLoadAuthSessionStore()
        )

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertEqual(
            state.errorMessage,
            "保存済みのログイン情報を読み込めませんでした。もう一度ログインしてください"
        )
    }

    func testAuthStateSignOutClearsStoredSessionAndCallsRepository() async throws {
        let session = makeTestSession(email: "michi@example.com")
        let store = InMemoryAuthSessionStore(initialSession: session)
        let repository = SignOutRecordingAuthRepository()
        let state = MegrumAuthState(repository: repository, sessionStore: store)

        XCTAssertTrue(state.isAuthenticated)

        await state.signOut()

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(try store.load())
        XCTAssertEqual(state.successMessage, "ログアウトしました")
        XCTAssertNil(state.errorMessage)

        let signedOutSessions = await repository.sessionsSnapshot()
        XCTAssertEqual(signedOutSessions, [session])
    }

    func testAuthStateSignOutReturnsToAuthScreenEvenIfRemoteLogoutFails() async throws {
        let session = makeTestSession(email: "michi@example.com")
        let store = InMemoryAuthSessionStore(initialSession: session)
        let state = MegrumAuthState(repository: SignOutFailingAuthRepository(), sessionStore: store)

        await state.signOut()

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(try store.load())
        XCTAssertEqual(state.successMessage, "ログアウトしました")
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateTimesOutAuthFailureAndStopsLoading() async {
        let state = MegrumAuthState(
            repository: HangingSignInAuthRepository(),
            authActionTimeoutNanoseconds: 1_000_000
        )

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(
            state.errorMessage,
            "通信に時間がかかっています。接続を確認してもう一度お試しください"
        )
    }

    func testAuthStateSignOutClearsLocalSessionWhenRemoteLogoutTimesOut() async throws {
        let session = makeTestSession(email: "michi@example.com")
        let store = InMemoryAuthSessionStore(initialSession: session)
        let state = MegrumAuthState(
            repository: HangingSignOutAuthRepository(),
            sessionStore: store,
            signOutTimeoutNanoseconds: 1_000_000
        )

        await state.signOut()

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(try store.load())
        XCTAssertEqual(state.successMessage, "ログアウトしました")
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateFactoryPreviewFallbackStartsAtAuthScreen() {
        let state = MegrumAuthStateFactory.make(environment: [:], infoDictionary: [:])

        XCTAssertFalse(state.isConfigured)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.session)
    }
}

private func makeTestSession(email: String) -> AuthSession {
    AuthSession(
        accessToken: "test_access_token",
        refreshToken: "test_refresh_token",
        user: AuthUser(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            email: email
        )
    )
}

private struct EmailConfirmationRequiredAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw DecodingError.keyNotFound(
            AuthCodingKey(stringValue: "access_token"),
            DecodingError.Context(codingPath: [], debugDescription: "Session is pending email confirmation")
        )
    }

    func signOut(session: AuthSession) async throws {}
}

private struct PasswordResetSuccessAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func sendPasswordReset(email: String) async throws {}

    func signOut(session: AuthSession) async throws {}
}

private final class FailingLoadAuthSessionStore: AuthSessionStore, @unchecked Sendable {
    func load() throws -> AuthSession? {
        throw TestAuthError.unused
    }

    func save(_ session: AuthSession) throws {}

    func clear() throws {}
}

private actor SignOutRecordingAuthRepository: MegrumAuthRepository {
    private var sessions: [AuthSession] = []

    nonisolated var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {
        sessions.append(session)
    }

    func sessionsSnapshot() -> [AuthSession] {
        sessions
    }
}

private struct SignOutFailingAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {
        throw TestAuthError.signOutFailed
    }
}

private struct HangingSignInAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {}
}

private struct HangingSignOutAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

private struct AuthCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        return nil
    }
}

private enum TestAuthError: Error {
    case unused
    case signOutFailed
}
