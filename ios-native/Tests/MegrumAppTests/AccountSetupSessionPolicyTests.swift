@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class AccountSetupSessionPolicyTests: XCTestCase {
    func testIncompleteStoredAccountStatusesReturnToLoginOnNormalLaunch() {
        XCTAssertTrue(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .registered,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
        XCTAssertTrue(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .verified,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
        XCTAssertTrue(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .onboarding,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
    }

    func testInteractiveIncompleteAccountCanContinueOnboarding() {
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .onboarding,
                sessionSource: .interactive,
                visualQAInitialScreen: nil
            )
        )
    }

    func testActiveAndRestrictedStatusesDoNotReturnToLogin() {
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .active,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .suspended,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .deletionRequested,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .deleted,
                sessionSource: .stored,
                visualQAInitialScreen: nil
            )
        )
    }

    func testVisualQAAccountSetupCanStillOpenOnboardingScreen() {
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .onboarding,
                sessionSource: .stored,
                visualQAInitialScreen: .accountSetup
            )
        )
    }

    @MainActor
    func testAuthStateMarksStoredSessionSourceFromSessionStore() {
        let session = makeAccountSetupPolicySession(email: "stored@example.com")
        let state = MegrumAuthState(
            repository: AccountSetupPolicyAuthRepository(session: session),
            sessionStore: InMemoryAuthSessionStore(initialSession: session)
        )

        XCTAssertEqual(state.session, session)
        XCTAssertEqual(state.sessionSource, .stored)
    }

    @MainActor
    func testAuthStateMarksInteractiveSessionSourceAfterSignIn() async {
        let session = makeAccountSetupPolicySession(email: "interactive@example.com")
        let state = MegrumAuthState(
            repository: AccountSetupPolicyAuthRepository(session: session),
            sessionStore: InMemoryAuthSessionStore()
        )

        await state.signIn(email: "interactive@example.com", password: "password123")

        XCTAssertEqual(state.session, session)
        XCTAssertEqual(state.sessionSource, .interactive)
    }
}

private func makeAccountSetupPolicySession(email: String) -> AuthSession {
    AuthSession(
        accessToken: "account_setup_policy_access_token",
        refreshToken: "account_setup_policy_refresh_token",
        user: AuthUser(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            email: email
        )
    )
}

private struct AccountSetupPolicyAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }
    let session: AuthSession

    func signIn(email: String, password: String) async throws -> AuthSession {
        session
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        session
    }

    func signOut(session: AuthSession) async throws {}
}
