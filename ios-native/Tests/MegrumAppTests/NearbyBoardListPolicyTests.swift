import Foundation
import MegrumCore
import XCTest
@testable import MegrumApp

final class NearbyBoardListPolicyTests: XCTestCase {
    private func makeThread(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        seriesName: String? = nil,
        latestActivityAt: Date = Date(timeIntervalSince1970: 1_780_000_000)
    ) -> BoardThread {
        BoardThread(
            id: id,
            authorID: UUID(),
            title: title,
            body: body,
            audience: .nearby3km,
            seriesName: seriesName,
            createdAt: latestActivityAt,
            latestActivityAt: latestActivityAt
        )
    }

    func testQueryMatchesTitleBodyAndSeriesCaseInsensitively() {
        let threads = [
            makeThread(title: "物販列どのくらい？", body: "北口側です"),
            makeThread(title: "終演後の交換", seriesName: "2026 LIVE"),
            makeThread(title: "ゆる交換", body: "カフェでのんびり")
        ]

        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, query: "物販").map(\.title), ["物販列どのくらい？"])
        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, query: "live").map(\.title), ["終演後の交換"])
        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, query: "カフェ").map(\.title), ["ゆる交換"])
        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, query: "  ").count, 3)
    }

    func testSeriesFilterMatchesExactSeriesOnly() {
        let threads = [
            makeThread(title: "A", seriesName: "2026 LIVE"),
            makeThread(title: "B", seriesName: "トレカ第3弾"),
            makeThread(title: "C")
        ]

        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, seriesName: "2026 LIVE").map(\.title), ["A"])
        XCTAssertEqual(NearbyBoardListPolicy.filtered(threads, seriesName: nil).count, 3)
    }

    func testOrderedPutsOpenableFirstThenLatestActivityDescending() {
        let lockedNew = makeThread(title: "locked-new", latestActivityAt: Date(timeIntervalSince1970: 1_780_000_400))
        let openOld = makeThread(title: "open-old", latestActivityAt: Date(timeIntervalSince1970: 1_780_000_100))
        let openNew = makeThread(title: "open-new", latestActivityAt: Date(timeIntervalSince1970: 1_780_000_300))
        let lockedOld = makeThread(title: "locked-old", latestActivityAt: Date(timeIntervalSince1970: 1_780_000_200))

        let ordered = NearbyBoardListPolicy.ordered(
            [lockedNew, openOld, openNew, lockedOld],
            lockedIDs: [lockedNew.id, lockedOld.id]
        )

        XCTAssertEqual(ordered.map(\.title), ["open-new", "open-old", "locked-new", "locked-old"])
    }

    func testAvailableSeriesNamesAreUniqueAndOrdered() {
        let threads = [
            makeThread(title: "A", seriesName: "2026 LIVE"),
            makeThread(title: "B", seriesName: "トレカ第3弾"),
            makeThread(title: "C", seriesName: "2026 LIVE"),
            makeThread(title: "D")
        ]

        XCTAssertEqual(NearbyBoardListPolicy.availableSeriesNames(in: threads), ["2026 LIVE", "トレカ第3弾"])
    }
}
