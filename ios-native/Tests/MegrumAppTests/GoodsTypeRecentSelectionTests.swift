import Foundation
import XCTest
@testable import MegrumApp

final class GoodsTypeRecentSelectionTests: XCTestCase {
    func testRecordingPutsNewestFirstAndDedupes() {
        let a = UUID(), b = UUID(), c = UUID()
        var raw = ""
        raw = GoodsTypeRecentSelection.updatedRaw(recording: a, into: raw)
        raw = GoodsTypeRecentSelection.updatedRaw(recording: b, into: raw)
        raw = GoodsTypeRecentSelection.updatedRaw(recording: c, into: raw)
        // 既存の a を再選択すると先頭に来て重複しない。
        raw = GoodsTypeRecentSelection.updatedRaw(recording: a, into: raw)

        XCTAssertEqual(GoodsTypeRecentSelection.recentIDs(from: raw), [a, c, b])
    }

    func testCapsAtFive() {
        var raw = ""
        let ids = (0..<8).map { _ in UUID() }
        for id in ids {
            raw = GoodsTypeRecentSelection.updatedRaw(recording: id, into: raw)
        }
        let recent = GoodsTypeRecentSelection.recentIDs(from: raw)
        XCTAssertEqual(recent.count, 5)
        // 最後に入れた5件が最近順で残る。
        XCTAssertEqual(recent, Array(ids.reversed().prefix(5)))
    }

    func testIgnoresMalformedEntries() {
        let a = UUID()
        let raw = "not-a-uuid,\(a.uuidString),,"
        XCTAssertEqual(GoodsTypeRecentSelection.recentIDs(from: raw), [a])
    }
}
