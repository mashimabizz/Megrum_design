@testable import MegrumApp
import XCTest

final class GroomViewerPresentationTests: XCTestCase {
    func testGroomViewerDragPresentationStateKeepsDownwardDragMetrics() {
        var state = GroomViewerDragPresentationState()

        state.update(with: CGSize(width: 12, height: 160))

        XCTAssertEqual(state.translation, CGSize(width: 12, height: 160))
        XCTAssertEqual(state.progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(state.verticalOffset, 160, accuracy: 0.0001)
        XCTAssertEqual(state.scale, 0.94, accuracy: 0.0001)
        XCTAssertEqual(state.cornerRadius, 14, accuracy: 0.0001)
        XCTAssertFalse(state.shouldDismiss(for: CGSize(width: 0, height: 100)))
        XCTAssertTrue(state.shouldDismiss(for: CGSize(width: 0, height: 101)))

        state.reset()

        XCTAssertEqual(state.translation, .zero)
    }

    func testGroomViewerDragPresentationStateIgnoresUpwardDragAndClampsMetrics() {
        var state = GroomViewerDragPresentationState()

        state.update(with: CGSize(width: 0, height: -40))

        XCTAssertEqual(state.translation, .zero)

        state.update(with: CGSize(width: 0, height: 800))

        XCTAssertEqual(state.progress, 1, accuracy: 0.0001)
        XCTAssertEqual(state.verticalOffset, 800, accuracy: 0.0001)
        XCTAssertEqual(state.scale, 0.88, accuracy: 0.0001)
        XCTAssertEqual(state.cornerRadius, 28, accuracy: 0.0001)
    }

    func testRelativeTimeFormatterUsesCompactJapaneseLabels() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(
            GroomPostRelativeTimeFormatter.relativeText(from: now.addingTimeInterval(-20), now: now),
            "たった今"
        )
        XCTAssertEqual(
            GroomPostRelativeTimeFormatter.relativeText(from: now.addingTimeInterval(-12 * 60), now: now),
            "12分前"
        )
        XCTAssertEqual(
            GroomPostRelativeTimeFormatter.relativeText(from: now.addingTimeInterval(-3 * 60 * 60), now: now),
            "3時間前"
        )
        XCTAssertEqual(
            GroomPostRelativeTimeFormatter.relativeText(from: now.addingTimeInterval(-2 * 24 * 60 * 60), now: now),
            "2日前"
        )
    }

    func testGroomViewerChromeLayoutKeepsChromeBelowTopObstruction() {
        XCTAssertEqual(GroomViewerChromeLayout.topPadding(safeAreaTop: 0), 86, accuracy: 0.0001)
        XCTAssertEqual(GroomViewerChromeLayout.topPadding(safeAreaTop: 64), 86, accuracy: 0.0001)
        XCTAssertEqual(GroomViewerChromeLayout.topPadding(safeAreaTop: 88), 98, accuracy: 0.0001)
        XCTAssertEqual(GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: 64), 76, accuracy: 0.0001)
    }
}
