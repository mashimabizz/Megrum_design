@testable import MegrumApp
import MegrumCore
import XCTest

final class AccountSetupSessionPolicyTests: XCTestCase {
    func testIncompleteAccountStatusesReturnToLoginOnNormalLaunch() {
        XCTAssertTrue(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .registered, visualQAInitialScreen: nil))
        XCTAssertTrue(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .verified, visualQAInitialScreen: nil))
        XCTAssertTrue(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .onboarding, visualQAInitialScreen: nil))
    }

    func testActiveAndRestrictedStatusesDoNotReturnToLogin() {
        XCTAssertFalse(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .active, visualQAInitialScreen: nil))
        XCTAssertFalse(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .suspended, visualQAInitialScreen: nil))
        XCTAssertFalse(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .deletionRequested, visualQAInitialScreen: nil))
        XCTAssertFalse(AccountSetupSessionPolicy.shouldReturnToLogin(accountStatus: .deleted, visualQAInitialScreen: nil))
    }

    func testVisualQAAccountSetupCanStillOpenOnboardingScreen() {
        XCTAssertFalse(
            AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: .onboarding,
                visualQAInitialScreen: .accountSetup
            )
        )
    }
}
