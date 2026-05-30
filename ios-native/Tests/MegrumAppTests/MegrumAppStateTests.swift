import MegrumApp
import MegrumCore
import MegrumData
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

    func testAppStateCanReplaceRepositoryAfterAuthChanges() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let nextViewer = UserProfile(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            handle: "signed_in",
            displayName: "Signed In"
        )

        await state.replaceRepository(SingleSnapshotRepository(viewer: nextViewer))

        XCTAssertEqual(state.viewer?.handle, "signed_in")
        XCTAssertTrue(state.inventory.isEmpty)
    }

    func testAppStateCompletesAccountSetupThroughRepository() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        let completed = await state.completeAccountSetup(displayName: "みちりおん", prefecture: "山形県")

        XCTAssertTrue(completed)
        XCTAssertEqual(state.viewer?.displayName, "みちりおん")
        XCTAssertEqual(state.viewer?.prefecture, "山形県")
        XCTAssertEqual(state.viewer?.accountStatus, .active)
        XCTAssertFalse(state.isSavingAccountSetup)
    }

    func testAuthStateSignsInThroughRepository() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertEqual(state.session?.user.email, "michi@example.com")
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateRestoresSessionFromStore() async {
        let store = InMemoryAuthSessionStore()
        let firstState = MegrumAuthState(repository: StubAuthRepository(), sessionStore: store)

        await firstState.signIn(email: "michi@example.com", password: "password123")
        let restoredState = MegrumAuthState(repository: StubAuthRepository(), sessionStore: store)

        XCTAssertEqual(restoredState.session?.user.email, "michi@example.com")
        XCTAssertTrue(restoredState.isAuthenticated)
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

private struct SingleSnapshotRepository: MegrumRepository {
    var viewer: UserProfile

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: viewer,
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }
}
