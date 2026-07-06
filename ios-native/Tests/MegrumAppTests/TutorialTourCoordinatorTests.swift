@testable import MegrumApp
import XCTest

@MainActor
final class TutorialTourCoordinatorTests: XCTestCase {
    func testStartsInactive() {
        let coordinator = TutorialTourCoordinator()
        XCTAssertFalse(coordinator.isActive)
        XCTAssertNil(coordinator.currentStep)
    }

    func testStartBeginsAtWelcome() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()
        XCTAssertTrue(coordinator.isActive)
        XCTAssertEqual(coordinator.currentStep, .welcome)
    }

    func testAdvanceWalksEveryStepThenFinishes() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()

        let expected: [TutorialTourStep] = [
            .homeSections, .inventory, .wish, .listing, .trades, .meguri, .completion,
        ]
        for step in expected {
            coordinator.advance()
            XCTAssertEqual(coordinator.currentStep, step)
        }

        // completion からもう一度進むと閉じる。
        coordinator.advance()
        XCTAssertNil(coordinator.currentStep)
        XCTAssertFalse(coordinator.isActive)
    }

    func testSkipClosesImmediately() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()
        coordinator.advance()
        coordinator.skip()
        XCTAssertNil(coordinator.currentStep)
    }

    func testTargetTabPerStep() {
        XCTAssertEqual(TutorialTourStep.welcome.targetTab, .home)
        XCTAssertEqual(TutorialTourStep.homeSections.targetTab, .home)
        XCTAssertEqual(TutorialTourStep.inventory.targetTab, .inventory)
        XCTAssertEqual(TutorialTourStep.wish.targetTab, .wish)
        XCTAssertEqual(TutorialTourStep.listing.targetTab, .wish)
        XCTAssertEqual(TutorialTourStep.trades.targetTab, .trades)
        XCTAssertEqual(TutorialTourStep.meguri.targetTab, .meguri)
        XCTAssertEqual(TutorialTourStep.completion.targetTab, .home)
    }

    func testWishSectionRouting() {
        XCTAssertEqual(TutorialTourStep.wish.requestedWishSection, .wishes)
        XCTAssertEqual(TutorialTourStep.listing.requestedWishSection, .listings)
        XCTAssertNil(TutorialTourStep.inventory.requestedWishSection)
    }

    func testCardStepsAreWelcomeAndCompletion() {
        XCTAssertTrue(TutorialTourStep.welcome.isCardStep)
        XCTAssertTrue(TutorialTourStep.completion.isCardStep)
        XCTAssertFalse(TutorialTourStep.homeSections.isCardStep)
        XCTAssertFalse(TutorialTourStep.inventory.isCardStep)
    }
}
