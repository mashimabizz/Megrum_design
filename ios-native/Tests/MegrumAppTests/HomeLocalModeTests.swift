@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeLocalModeTests: XCTestCase {
    func testLocalActivityStatusAndWindowText() {
        let start = Date(timeIntervalSince1970: 1_780_240_800)
        let now = start.addingTimeInterval(30 * 60)
        let settings = HomeLocalActivitySettings(
            isEnabled: true,
            venue: " 東京ドーム ",
            startedAt: start,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(settings.status(now: now), .live)
        XCTAssertEqual(settings.status(now: start.addingTimeInterval(121 * 60)), .expired)
        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "東京都"), "東京ドーム")
        XCTAssertEqual(settings.timeWindowText(now: now, calendar: calendar), "15:20-17:20")
        XCTAssertEqual(settings.radiusText, "500m")
    }

    func testLocalActivityUsesPrefectureFallbackWhenVenueIsEmpty() {
        let settings = HomeLocalActivitySettings(
            isEnabled: false,
            venue: " ",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 1_000,
            selectedCarryingIDs: []
        )

        XCTAssertEqual(settings.status(), .off)
        XCTAssertEqual(settings.displayVenue(fallbackPrefecture: "大阪府"), "大阪府周辺")
        XCTAssertEqual(settings.radiusText, "1km")
    }

    func testCarryingCandidatesFilterViewerItemsAndDeduplicate() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let viewerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            ownerID: viewerID,
            title: "ランダムトレカ A",
            tags: [GoodsTag(id: UUID(), name: "会場限定")],
            quantity: 2
        )
        let partnerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            ownerID: partnerID,
            title: "ランダムトレカ B"
        )

        let candidates = HomeLocalCarryingCandidate.candidates(
            from: [viewerItem, partnerItem, viewerItem],
            viewerID: viewerID
        )

        XCTAssertEqual(candidates.map(\.id), [viewerItem.id])
        XCTAssertEqual(candidates.first?.subtitle, "会場限定")
        XCTAssertEqual(candidates.first?.quantity, 2)
    }

    func testCarryingSummaryAndCodecRoundTripSelection() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let candidates = [
            HomeLocalCarryingCandidate(
                item: GoodsItem(id: firstID, ownerID: UUID(), title: "スア 春ver.")
            ),
            HomeLocalCarryingCandidate(
                item: GoodsItem(id: secondID, ownerID: UUID(), title: "ジョンウ ラキドロ")
            )
        ]
        let encoded = HomeLocalCarryingSelectionCodec.encode([secondID, firstID])
        let decoded = HomeLocalCarryingSelectionCodec.decode(encoded)
        let summary = HomeLocalCarryingSummary(candidates: candidates, selectedIDs: decoded)

        XCTAssertEqual(decoded, [firstID, secondID])
        XCTAssertEqual(summary.countText, "持参 2/2件")
        XCTAssertEqual(summary.titleText, "スア 春ver.、ジョンウ ラキドロ")
    }

    func testDraftStartsWindowWhenModeIsEnabled() {
        let now = Date(timeIntervalSince1970: 1_780_200_000)
        let original = HomeLocalActivitySettings(
            isEnabled: false,
            venue: "",
            startedAt: nil,
            durationMinutes: 120,
            radiusMeters: 500,
            selectedCarryingIDs: []
        )
        var draft = HomeLocalActivityDraft(settings: original, fallbackPrefecture: nil)
        draft.isEnabled = true
        draft.venue = "幕張メッセ"

        let saved = draft.settings(savedAt: now, original: original)

        XCTAssertTrue(saved.isEnabled)
        XCTAssertEqual(saved.venue, "幕張メッセ")
        XCTAssertEqual(saved.startedAt, now)
        XCTAssertEqual(saved.status(now: now), .live)
    }
}
