import Foundation
import XCTest
@testable import MegrumApp

final class ChatHeaderCollapseTrackerTests: XCTestCase {
    func testCollapsesOnDownwardScrollAndStaysWhenStopped() {
        var tracker = ChatHeaderCollapseTracker()
        var collapsed = false
        collapsed = tracker.updatedCollapsedState(contentTop: -1000, isCollapsed: collapsed)
        XCTAssertFalse(collapsed)
        // 下方向スクロール（contentTop 減少）で収納
        collapsed = tracker.updatedCollapsedState(contentTop: -1012, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        // 停止（同じ値）でも収納のまま
        collapsed = tracker.updatedCollapsedState(contentTop: -1012, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        // 端のバウンス程度（+40）では戻らない
        collapsed = tracker.updatedCollapsedState(contentTop: -972, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -992, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
    }

    func testExpandsAfterSustainedUpwardScroll() {
        var tracker = ChatHeaderCollapseTracker()
        var collapsed = false
        collapsed = tracker.updatedCollapsedState(contentTop: -1000, isCollapsed: collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -1020, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        // 上方向へ累積150pt以上で展開
        collapsed = tracker.updatedCollapsedState(contentTop: -960, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -890, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -860, isCollapsed: collapsed)
        XCTAssertFalse(collapsed)
    }

    func testLayoutJumpDoesNotChangeState() {
        var tracker = ChatHeaderCollapseTracker()
        var collapsed = false
        collapsed = tracker.updatedCollapsedState(contentTop: -1000, isCollapsed: collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -1020, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        // キーボード表示などの大ジャンプでは変化しない
        collapsed = tracker.updatedCollapsedState(contentTop: -1400, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
        collapsed = tracker.updatedCollapsedState(contentTop: -1000, isCollapsed: collapsed)
        XCTAssertTrue(collapsed)
    }
}
