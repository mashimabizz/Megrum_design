@testable import MegrumApp
import MegrumCore
import XCTest

final class TradeScheduleCalendarWindowTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testFiveDayWindowBuildsVisibleIntervalAndDays() {
        let anchor = date(year: 2026, month: 6, day: 25, hour: 15)
        let window = TradeScheduleCalendarWindow(mode: .fiveDays, anchorDate: anchor, calendar: calendar)

        XCTAssertEqual(window.visibleInterval.start, date(year: 2026, month: 6, day: 25))
        XCTAssertEqual(window.visibleInterval.end, date(year: 2026, month: 6, day: 30))
        XCTAssertEqual(
            window.fiveVisibleDays,
            [
                date(year: 2026, month: 6, day: 25),
                date(year: 2026, month: 6, day: 26),
                date(year: 2026, month: 6, day: 27),
                date(year: 2026, month: 6, day: 28),
                date(year: 2026, month: 6, day: 29),
            ]
        )
        XCTAssertEqual(window.movedAnchor(by: 5), date(year: 2026, month: 6, day: 30, hour: 15))
    }

    func testMonthWindowBuildsPaddedGridAndMovesByMonth() throws {
        let anchor = date(year: 2026, month: 6, day: 15, hour: 9)
        let window = TradeScheduleCalendarWindow(mode: .month, anchorDate: anchor, calendar: calendar)
        let grid = window.monthGridDays

        XCTAssertEqual(window.visibleInterval.start, date(year: 2026, month: 6, day: 1))
        XCTAssertEqual(window.visibleInterval.end, date(year: 2026, month: 7, day: 1))
        XCTAssertNil(try XCTUnwrap(grid.first))
        XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(grid.dropFirst().first)), date(year: 2026, month: 6, day: 1))
        XCTAssertEqual(grid.compactMap(\.self).count, 30)
        XCTAssertEqual(grid.count % 7, 0)
        XCTAssertEqual(window.movedAnchor(by: 1), date(year: 2026, month: 7, day: 15, hour: 9))
    }

    func testSchedulesOnDayUsesOverlapBoundaries() {
        let day = date(year: 2026, month: 1, day: 10)
        let window = TradeScheduleCalendarWindow(mode: .fiveDays, anchorDate: day, calendar: calendar)
        let overlap = makeSchedule(
            idSuffix: "901",
            startAt: date(year: 2026, month: 1, day: 10, hour: 23),
            endAt: date(year: 2026, month: 1, day: 11, hour: 1)
        )
        let endsAtDayStart = makeSchedule(
            idSuffix: "902",
            startAt: date(year: 2026, month: 1, day: 9, hour: 23),
            endAt: date(year: 2026, month: 1, day: 10)
        )
        let startsAtDayEnd = makeSchedule(
            idSuffix: "903",
            startAt: date(year: 2026, month: 1, day: 11),
            endAt: date(year: 2026, month: 1, day: 11, hour: 1)
        )

        let result = window.schedules(on: day, from: [endsAtDayStart, overlap, startsAtDayEnd])

        XCTAssertEqual(result, [overlap])
    }

    private func makeSchedule(idSuffix: String, startAt: Date, endAt: Date) -> PersonalSchedule {
        PersonalSchedule(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000900")!,
            title: "予定\(idSuffix)",
            startAt: startAt,
            endAt: endAt
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
