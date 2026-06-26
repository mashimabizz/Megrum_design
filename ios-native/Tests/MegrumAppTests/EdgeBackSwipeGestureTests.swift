@testable import MegrumApp
import XCTest

final class EdgeBackSwipeGestureTests: XCTestCase {
    func testLeftEdgeRightSwipeTriggersBack() {
        XCTAssertTrue(
            EdgeBackSwipeResolver.shouldTrigger(
                startLocation: CGPoint(x: 12, y: 300),
                translation: CGSize(width: 72, height: 10),
                predictedEndTranslationWidth: 90
            )
        )
    }

    func testSwipeMustStartNearLeadingEdge() {
        XCTAssertFalse(
            EdgeBackSwipeResolver.shouldTrigger(
                startLocation: CGPoint(x: EdgeBackSwipeResolver.leadingEdgeWidth + 1, y: 300),
                translation: CGSize(width: 120, height: 8),
                predictedEndTranslationWidth: 140
            )
        )
    }

    func testLeftSwipeDoesNotTriggerBack() {
        XCTAssertFalse(
            EdgeBackSwipeResolver.shouldTrigger(
                startLocation: CGPoint(x: 12, y: 300),
                translation: CGSize(width: -90, height: 8),
                predictedEndTranslationWidth: -120
            )
        )
    }

    func testVerticalDragDoesNotTriggerBack() {
        XCTAssertFalse(
            EdgeBackSwipeResolver.shouldTrigger(
                startLocation: CGPoint(x: 12, y: 300),
                translation: CGSize(width: 72, height: 90),
                predictedEndTranslationWidth: 110
            )
        )
    }

    func testShortSwipeDoesNotTriggerBack() {
        XCTAssertFalse(
            EdgeBackSwipeResolver.shouldTrigger(
                startLocation: CGPoint(x: 12, y: 300),
                translation: CGSize(width: 30, height: 4),
                predictedEndTranslationWidth: 54
            )
        )
    }

    func testInteractiveBackSwipeTracksRightHorizontalDragFromAnywhere() {
        XCTAssertEqual(
            InteractiveBackSwipeResolver.trackedOffset(
                translation: CGSize(width: 96, height: 8),
                screenWidth: 390
            ),
            96
        )
    }

    func testInteractiveBackSwipeIgnoresLeftAndVerticalDrags() {
        XCTAssertNil(
            InteractiveBackSwipeResolver.trackedOffset(
                translation: CGSize(width: -96, height: 8),
                screenWidth: 390
            )
        )
        XCTAssertNil(
            InteractiveBackSwipeResolver.trackedOffset(
                translation: CGSize(width: 96, height: 120),
                screenWidth: 390
            )
        )
    }

    func testInteractiveBackSwipeTriggersAfterThresholdOrProjectedFlick() {
        XCTAssertTrue(
            InteractiveBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 86, height: 8),
                predictedEndTranslationWidth: 88,
                screenWidth: 390
            )
        )
        XCTAssertTrue(
            InteractiveBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 36, height: 4),
                predictedEndTranslationWidth: 132,
                screenWidth: 390
            )
        )
        XCTAssertFalse(
            InteractiveBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 36, height: 4),
                predictedEndTranslationWidth: 64,
                screenWidth: 390
            )
        )
    }

    func testSlideBackSwipeTracksRightDragAndDismissesByFraction() {
        XCTAssertEqual(
            MegrumSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: 118, height: 12),
                screenWidth: 390
            ),
            118
        )
        XCTAssertTrue(
            MegrumSlideBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 118, height: 12),
                predictedEndTranslationWidth: 118,
                screenWidth: 390
            )
        )
    }

    func testSlideBackSwipeKeepsPreviousScreenForShortOrVerticalDrag() {
        XCTAssertNil(
            MegrumSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: -118, height: 12),
                screenWidth: 390
            )
        )
        XCTAssertNil(
            MegrumSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: 118, height: 140),
                screenWidth: 390
            )
        )
        XCTAssertFalse(
            MegrumSlideBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 32, height: 2),
                predictedEndTranslationWidth: 54,
                screenWidth: 390
            )
        )
    }
}
