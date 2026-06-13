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
        let store = FailingLoadAuthSessionStore()
        let state = MegrumAuthState(repository: PasswordResetSuccessAuthRepository(), sessionStore: store)

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.errorMessage)
        XCTAssertTrue(store.didClear)
    }

    func testAuthStateSignInActivatesSessionEvenIfSessionSaveFails() async {
        let session = makeTestSession(email: "michi@example.com")
        let state = MegrumAuthState(
            repository: SignInSuccessAuthRepository(session: session),
            sessionStore: FailingSaveAuthSessionStore()
        )

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertEqual(state.session, session)
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(
            state.successMessage,
            "ログインしました。ただし保存に失敗したため、次回起動時は再ログインが必要な場合があります"
        )
        XCTAssertFalse(state.isLoading)
    }

    func testAuthStateRefreshesStoredSessionBeforeUse() async throws {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        let storedSession = AuthSession(
            accessToken: "old_access_token",
            refreshToken: "old_refresh_token",
            expiresIn: 3_600,
            expiresAt: now.addingTimeInterval(60),
            user: AuthUser(
                id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                email: "michi@example.com"
            )
        )
        let refreshedSession = AuthSession(
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token",
            expiresIn: 3_600,
            expiresAt: now.addingTimeInterval(3_600),
            user: storedSession.user
        )
        let store = InMemoryAuthSessionStore(initialSession: storedSession)
        let repository = RefreshingAuthRepository(refreshedSession: refreshedSession)
        let state = MegrumAuthState(repository: repository, sessionStore: store)

        let didRefresh = await state.refreshSessionIfNeeded(now: now, leeway: 300)

        XCTAssertTrue(didRefresh)
        XCTAssertEqual(state.session, refreshedSession)
        XCTAssertEqual(try store.load(), refreshedSession)
        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(state.isLoading)
        let refreshInputs = await repository.refreshInputs()
        XCTAssertEqual(refreshInputs, [storedSession])
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

    func testAuthStateFactoryCanForceVisualQAPreviewSession() {
        let state = MegrumAuthStateFactory.make(
            environment: [
                "MEGRUM_VISUAL_QA_PREVIEW_AUTH": "1",
                "MEGRUM_SUPABASE_URL": "https://example.supabase.co",
                "MEGRUM_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test"
            ],
            infoDictionary: [:]
        )

        XCTAssertFalse(state.isConfigured)
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertEqual(state.session?.user.email, "preview@megrum.jp")
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
    private(set) var didClear = false

    func load() throws -> AuthSession? {
        throw TestAuthError.unused
    }

    func save(_ session: AuthSession) throws {}

    func clear() throws {
        didClear = true
    }
}

private struct SignInSuccessAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }
    var session: AuthSession

    func signIn(email: String, password: String) async throws -> AuthSession {
        session
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {}
}

private actor RefreshingAuthRepository: MegrumAuthRepository {
    nonisolated var isConfigured: Bool { true }
    private let refreshedSession: AuthSession
    private var refreshedInputs: [AuthSession] = []

    init(refreshedSession: AuthSession) {
        self.refreshedSession = refreshedSession
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw TestAuthError.unused
    }

    func signOut(session: AuthSession) async throws {}

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        refreshedInputs.append(session)
        return refreshedSession
    }

    func refreshInputs() -> [AuthSession] {
        refreshedInputs
    }
}

private final class FailingSaveAuthSessionStore: AuthSessionStore, @unchecked Sendable {
    func load() throws -> AuthSession? {
        nil
    }

    func save(_ session: AuthSession) throws {
        throw TestAuthError.unused
    }

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
