@testable import MegrumApp
import XCTest

final class GroomViewerPresentationTests: XCTestCase {
    func testGroomViewerDragPresentationStateKeepsDownwardDragMetrics() {
        var state = GroomViewerDragPresentationState()

        state.update(with: CGSize(width: 12, height: 160))

        // 横方向は無視して下方向のみ保持する。
        XCTAssertEqual(state.translation, CGSize(width: 0, height: 160))
        // 見た目のオフセットはラバーバンドで実移動より小さくなる。
        XCTAssertLessThan(state.verticalOffset, 160)
        XCTAssertGreaterThan(state.verticalOffset, 0)
        XCTAssertEqual(state.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(state.cornerRadius, 0, accuracy: 0.0001)
        XCTAssertFalse(state.shouldDismiss(for: CGSize(width: 0, height: 130)))
        XCTAssertTrue(state.shouldDismiss(for: CGSize(width: 0, height: 131)))

        state.reset()

        XCTAssertEqual(state.translation, .zero)
    }

    func testGroomViewerDragPresentationStateIgnoresUpwardDragAndClampsMetrics() {
        var state = GroomViewerDragPresentationState()

        state.update(with: CGSize(width: 0, height: -40))

        XCTAssertEqual(state.translation, .zero)

        state.update(with: CGSize(width: 120, height: 800))

        // 横方向は無視され、下方向のみ反映される。
        XCTAssertEqual(state.translation.width, 0, accuracy: 0.0001)
        // 見た目のオフセットは画面1/10相当（84pt）へラバーバンドで漸近し、超えない。
        XCTAssertLessThan(state.verticalOffset, 84)
        XCTAssertGreaterThan(state.verticalOffset, 70)
        // 縮小・角丸の演出は無し。
        XCTAssertEqual(state.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(state.cornerRadius, 0, accuracy: 0.0001)
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

    @MainActor
    func testGroomViewerChromeLayoutKeepsChromeBelowTopObstruction() {
        // 黒帯はステータスバー実測高（テスト環境ではウィンドウなし=0）と
        // 渡された safeAreaTop の大きい方。クロームはその 10pt 下から始まる。
        XCTAssertEqual(GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: 64), 64, accuracy: 0.0001)
        XCTAssertEqual(GroomViewerChromeLayout.topPadding(safeAreaTop: 64), 74, accuracy: 0.0001)
        XCTAssertEqual(GroomViewerChromeLayout.topPadding(safeAreaTop: 88), 98, accuracy: 0.0001)
    }
}
