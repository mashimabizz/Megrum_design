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

    func testStartAtSpecificStep() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start(at: .inventory)
        XCTAssertEqual(coordinator.currentStep, .inventory)
    }

    func testAdvanceWalksEveryStepThenFinishes() {
        let coordinator = TutorialTourCoordinator()
        coordinator.start()

        let expected: [TutorialTourStep] = [
            .homeSectionUserTag, .homeSectionUser, .homeSectionHaves,
            .inventory, .wish, .listing, .trades, .meguri, .completion,
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
        XCTAssertEqual(TutorialTourStep.homeSectionUserTag.targetTab, .home)
        XCTAssertEqual(TutorialTourStep.homeSectionUser.targetTab, .home)
        XCTAssertEqual(TutorialTourStep.homeSectionHaves.targetTab, .home)
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

    func testPresentationKinds() {
        XCTAssertEqual(TutorialTourStep.welcome.presentation, .centerCard)
        XCTAssertEqual(TutorialTourStep.completion.presentation, .centerCard)
        XCTAssertEqual(TutorialTourStep.meguri.presentation, .banner)
        XCTAssertEqual(TutorialTourStep.homeSectionUserTag.presentation, .spotlight)
        XCTAssertEqual(TutorialTourStep.inventory.presentation, .spotlight)
    }

    func testHomeSectionStepsHaveFocusAnchors() {
        XCTAssertEqual(TutorialTourStep.homeSectionUserTag.homeFocusAnchor, .homeSectionUserTag)
        XCTAssertEqual(TutorialTourStep.homeSectionUser.homeFocusAnchor, .homeSectionUser)
        XCTAssertEqual(TutorialTourStep.homeSectionHaves.homeFocusAnchor, .homeSectionHaves)
        XCTAssertNil(TutorialTourStep.inventory.homeFocusAnchor)
        XCTAssertNil(TutorialTourStep.welcome.homeFocusAnchor)
    }

    func testSpotlightStepsHaveAnchors() {
        for step in TutorialTourStep.allCases where step.presentation == .spotlight {
            XCTAssertNotNil(step.spotlightAnchor, "spotlight step \(step) must have an anchor")
        }
        XCTAssertNil(TutorialTourStep.welcome.spotlightAnchor)
        XCTAssertNil(TutorialTourStep.meguri.spotlightAnchor)
        XCTAssertNil(TutorialTourStep.completion.spotlightAnchor)
    }

    func testVisualQAValueParsing() {
        XCTAssertEqual(TutorialTourStep(visualQAValue: "welcome"), .welcome)
        XCTAssertEqual(TutorialTourStep(visualQAValue: "home-1"), .homeSectionUserTag)
        XCTAssertEqual(TutorialTourStep(visualQAValue: "home-2"), .homeSectionUser)
        XCTAssertEqual(TutorialTourStep(visualQAValue: "home-3"), .homeSectionHaves)
        XCTAssertEqual(TutorialTourStep(visualQAValue: "inventory"), .inventory)
        XCTAssertEqual(TutorialTourStep(visualQAValue: " Meguri "), .meguri)
        XCTAssertEqual(TutorialTourStep(visualQAValue: "4"), .inventory)
        XCTAssertNil(TutorialTourStep(visualQAValue: "unknown"))
        XCTAssertNil(TutorialTourStep(visualQAValue: "99"))
    }

    func testVisualQATutorialStepEnvironmentParsing() {
        XCTAssertEqual(
            VisualQAPreviewMode.tutorialStartStep(
                environment: ["MEGRUM_VISUAL_QA_TUTORIAL_STEP": "trades"]
            ),
            .trades
        )
        XCTAssertNil(
            VisualQAPreviewMode.tutorialStartStep(environment: [:])
        )
    }
}
