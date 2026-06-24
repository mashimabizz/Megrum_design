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
}
