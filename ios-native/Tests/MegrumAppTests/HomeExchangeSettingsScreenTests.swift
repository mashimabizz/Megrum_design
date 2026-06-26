import Foundation
import CoreGraphics
import MegrumCore
@testable import MegrumApp
import XCTest

final class HomeExchangeSettingsScreenTests: XCTestCase {
    func testCalendarDragSelectionAllowsOnlyHorizontalSameRow() {
        XCTAssertTrue(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 11,
                translation: CGSize(width: 90, height: 10)
            )
        )

        XCTAssertFalse(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 15,
                translation: CGSize(width: 90, height: 10)
            )
        )

        XCTAssertFalse(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 11,
                translation: CGSize(width: 10, height: 90)
            )
        )
    }

    func testCalendarDragSelectionResolverKeepsAccumulatedDatesWhenFinalRangeShrinks() {
        let visibleKeys = [
            "2026-06-01",
            "2026-06-02",
            "2026-06-03",
            "2026-06-04",
            "2026-06-05"
        ]

        let resolvedKeys = HomeExchangeCalendarDragSelectionResolver.resolvedKeys(
            accumulatedKeys: ["2026-06-03", "2026-06-04"],
            finalKeys: ["2026-06-01", "2026-06-02"],
            visibleKeys: visibleKeys
        )

        XCTAssertEqual(
            resolvedKeys,
            ["2026-06-01", "2026-06-02", "2026-06-03", "2026-06-04"]
        )
    }

    func testReflectedListingConditionsUseMultipleMemoMessageForSameDate() {
        let now = makeDate(year: 2026, month: 6, day: 25)
        let listings = [
            makeListing(localPrefecture: "東京都", localPlaceMemo: "東京駅付近", localSchedule: "6/28"),
            makeListing(localPrefecture: "東京都", localPlaceMemo: "渋谷で相談", localSchedule: "6/28")
        ]

        let details = HomeExchangeListingConditionReflector.reflectedDetails(
            from: listings,
            calendar: makeCalendar(),
            now: now
        )

        XCTAssertEqual(details["2026-06-28"]?.prefecture, "東京都")
        XCTAssertEqual(details["2026-06-28"]?.memo, HomeExchangeListingConditionReflector.multipleMemoText)
    }

    func testReflectedListingConditionsIgnoreConsultSchedules() {
        let listing = makeListing(
            localPrefecture: "東京都",
            localPlaceMemo: "東京駅付近",
            localSchedule: IndividualListingExchangeSummary.defaultLocalSchedule
        )

        let details = HomeExchangeListingConditionReflector.reflectedDetails(
            from: [listing],
            calendar: makeCalendar(),
            now: makeDate(year: 2026, month: 6, day: 25)
        )

        XCTAssertTrue(details.isEmpty)
    }

    func testDefaultExchangeSettingsBuildListingSummaryFromConfiguredDefault() {
        let settings = HomeDefaultExchangeSettings(
            preference: .local,
            localPrefecture: "大阪府",
            localDateKeys: ["2026-07-01", "2026-07-03"],
            mailShippingFee: .owner,
            mailShippingDays: .oneDay
        )

        let summary = settings.makeListingExchangeSummary(
            now: makeDate(year: 2026, month: 6, day: 27)
        )

        XCTAssertEqual(summary.handoffMethod, .local)
        XCTAssertEqual(summary.localPrefecture, "大阪府")
        XCTAssertEqual(summary.localSchedule, "7/1、7/3")
        XCTAssertEqual(summary.shippingFee, .owner)
        XCTAssertEqual(summary.shippingDays, .oneDay)
    }

    private func makeListing(
        localPrefecture: String,
        localPlaceMemo: String,
        localSchedule: String,
        status: IndividualListingStatus = .active
    ) -> IndividualListing {
        let summary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: localPrefecture,
            localPlaceMemo: localPlaceMemo,
            localSchedule: localSchedule
        )
        return IndividualListing(
            id: UUID(),
            ownerID: UUID(),
            haves: [],
            status: status,
            note: summary.storageLine
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        makeCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }
}
