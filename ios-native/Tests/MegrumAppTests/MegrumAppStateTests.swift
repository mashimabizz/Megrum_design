import MegrumApp
import MegrumCore
import XCTest

@MainActor
final class MegrumAppStateTests: XCTestCase {
    func testPreviewStateLoadsInitialSnapshot() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
        XCTAssertFalse(state.wishes.isEmpty)
        XCTAssertFalse(state.proposals.isEmpty)
        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertFalse(state.threads.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testFactoryFallsBackToPreviewWithoutSupabaseConfig() async {
        let state = MegrumAppStateFactory.make(environment: [:], infoDictionary: [:])

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }

    func testAuthStateSignsInThroughRepository() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertEqual(state.session?.user.email, "michi@example.com")
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateValidatesSignUpPasswordLength() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signUp(email: "michi@example.com", password: "short", handle: "michi1")

        XCTAssertNil(state.session)
        XCTAssertEqual(state.errorMessage, "メールアドレスと8文字以上のパスワードを入力してください")
    }
}

private struct StubAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        AuthSession(
            accessToken: "stub_access_token",
            user: AuthUser(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                email: email
            )
        )
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        AuthSession(
            accessToken: "stub_access_token",
            user: AuthUser(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                email: input.email
            )
        )
    }

    func signOut(session: AuthSession) async throws {}
}
