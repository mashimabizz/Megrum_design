@testable import MegrumApp
import XCTest

final class OnboardingTutorialProgressStoreTests: XCTestCase {
    private func makeDefaults() throws -> (UserDefaults, String) {
        let suiteName = "megrum.onboarding-tutorial.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }

    func testTourDefaultsToNotCompleted() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let userID = UUID()

        XCTAssertFalse(OnboardingTutorialProgressStore.isTourCompleted(userID: userID, defaults: defaults))
    }

    func testMarkTourCompletedPersists() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let userID = UUID()

        OnboardingTutorialProgressStore.markTourCompleted(userID: userID, defaults: defaults)

        XCTAssertTrue(OnboardingTutorialProgressStore.isTourCompleted(userID: userID, defaults: defaults))
    }

    func testMissionFlagIsIndependentFromTourFlag() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let userID = UUID()

        OnboardingTutorialProgressStore.markTourCompleted(userID: userID, defaults: defaults)

        XCTAssertTrue(OnboardingTutorialProgressStore.isTourCompleted(userID: userID, defaults: defaults))
        XCTAssertFalse(OnboardingTutorialProgressStore.isMissionCompleted(userID: userID, defaults: defaults))

        OnboardingTutorialProgressStore.markMissionCompleted(userID: userID, defaults: defaults)
        XCTAssertTrue(OnboardingTutorialProgressStore.isMissionCompleted(userID: userID, defaults: defaults))
    }

    func testFlagsAreScopedPerUser() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let userA = UUID()
        let userB = UUID()

        OnboardingTutorialProgressStore.markTourCompleted(userID: userA, defaults: defaults)

        XCTAssertTrue(OnboardingTutorialProgressStore.isTourCompleted(userID: userA, defaults: defaults))
        XCTAssertFalse(OnboardingTutorialProgressStore.isTourCompleted(userID: userB, defaults: defaults))
    }
}
