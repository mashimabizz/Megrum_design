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

    func testInteractiveBackSwipePresentationStateTracksWidthOffsetAndTrigger() {
        var state = InteractiveBackSwipePresentationState()

        state.updateContainerWidth(420)

        XCTAssertEqual(state.containerWidth, 420)
        XCTAssertFalse(
            state.beginTrackingIfNeeded(
                translation: CGSize(width: 24, height: 72)
            )
        )

        XCTAssertTrue(
            state.beginTrackingIfNeeded(
                translation: CGSize(width: 96, height: 8)
            )
        )

        state.dragOffset = state.trackedOffset(translation: CGSize(width: 96, height: 8))

        XCTAssertTrue(state.isTrackingBackSwipe)
        XCTAssertEqual(state.dragOffset, 96)
        XCTAssertTrue(
            state.shouldTrigger(
                translation: CGSize(width: 86, height: 8),
                predictedEndTranslationWidth: 88
            )
        )

        state.stopTracking()

        XCTAssertFalse(
            state.shouldTrigger(
                translation: CGSize(width: 86, height: 8),
                predictedEndTranslationWidth: 140
            )
        )

        state.resetDragOffset()

        XCTAssertEqual(state.dragOffset, 0)
    }

    func testMeguriMessageBackSwipeTriggersFromAnywhere() {
        XCTAssertTrue(
            MeguriMessageNavigationBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 92, height: 8),
                predictedEndTranslationWidth: 94,
                screenWidth: 390
            )
        )
        XCTAssertTrue(
            MeguriMessageNavigationBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 34, height: 3),
                predictedEndTranslationWidth: 132,
                screenWidth: 390
            )
        )
        XCTAssertFalse(
            MeguriMessageNavigationBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: -92, height: 8),
                predictedEndTranslationWidth: -120,
                screenWidth: 390
            )
        )
        XCTAssertFalse(
            MeguriMessageNavigationBackSwipeResolver.shouldTrigger(
                translation: CGSize(width: 92, height: 140),
                predictedEndTranslationWidth: 132,
                screenWidth: 390
            )
        )
    }

    func testSlideBackSwipeTracksRightDragAndDismissesByFraction() {
        XCTAssertEqual(MegrumSlideBackSwipeInteractionScope.leadingEdge, .leadingEdge)
        XCTAssertEqual(MegrumSlideBackSwipeInteractionScope.fullScreen, .fullScreen)

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

    func testSlidePresentationDragStateTracksOffsetAndDismissDecision() {
        var state = MegrumSlidePresentationDragState()

        XCTAssertFalse(
            state.beginTrackingIfNeeded(
                translation: CGSize(width: 24, height: 90),
                screenWidth: 390
            )
        )
        XCTAssertFalse(state.isTrackingDismissDrag)

        XCTAssertTrue(
            state.beginTrackingIfNeeded(
                translation: CGSize(width: 120, height: 12),
                screenWidth: 390
            )
        )
        state.dragOffset = state.clampedDragOffset(
            translation: CGSize(width: 420, height: 12),
            screenWidth: 390
        )

        XCTAssertTrue(state.isTrackingDismissDrag)
        XCTAssertEqual(state.dragOffset, 390)
        XCTAssertTrue(
            state.shouldDismiss(
                translation: CGSize(width: 120, height: 12),
                predictedEndTranslationWidth: 120,
                screenWidth: 390
            )
        )

        state.stopTracking()

        XCTAssertFalse(
            state.shouldDismiss(
                translation: CGSize(width: 120, height: 12),
                predictedEndTranslationWidth: 160,
                screenWidth: 390
            )
        )

        state.resetDragOffset()

        XCTAssertEqual(state.dragOffset, 0)
    }
}

final class MeguriInboxSlideHostGeometryTests: XCTestCase {
    func testRestingOffsetFollowsFingerDuringOpenDrag() {
        XCTAssertEqual(
            MeguriInboxSlideHostGeometry.restingOffset(
                isPresented: false,
                openDragOffset: 214,
                screenWidth: 390
            ),
            214
        )
        // コミット後（isPresented=true）もドラッグ用オフセットが残っている間はそれを優先
        XCTAssertEqual(
            MeguriInboxSlideHostGeometry.restingOffset(
                isPresented: true,
                openDragOffset: 42,
                screenWidth: 390
            ),
            42
        )
    }

    func testRestingOffsetIsZeroWhenPresented() {
        XCTAssertEqual(
            MeguriInboxSlideHostGeometry.restingOffset(
                isPresented: true,
                openDragOffset: nil,
                screenWidth: 390
            ),
            0
        )
    }

    func testRestingOffsetParksBeyondShadowWhenClosed() {
        // 閉時は影（radius 24, x:-8）が右端へ映り込まないよう画面幅より余分に退避
        XCTAssertEqual(
            MeguriInboxSlideHostGeometry.restingOffset(
                isPresented: false,
                openDragOffset: nil,
                screenWidth: 390
            ),
            390 + MeguriInboxSlideHostGeometry.parkedShadowMargin
        )
        XCTAssertGreaterThan(MeguriInboxSlideHostGeometry.parkedShadowMargin, 32)
    }
}
