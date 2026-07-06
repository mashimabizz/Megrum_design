import Foundation
@testable import MegrumApp
import XCTest

final class ChatTimestampFormatterTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)!
    }

    func testTimeTextUsesMinutesHoursThenClock() {
        let now = date("2026-07-06 15:00")
        XCTAssertEqual(ChatTimestampFormatter.timeText(for: date("2026-07-06 14:59"), now: now, calendar: calendar), "1分前")
        XCTAssertEqual(ChatTimestampFormatter.timeText(for: date("2026-07-06 14:30"), now: now, calendar: calendar), "30分前")
        XCTAssertEqual(ChatTimestampFormatter.timeText(for: date("2026-07-06 09:00"), now: now, calendar: calendar), "6時間前")
        // 日を跨いだら経過時間に関わらず HH:mm
        XCTAssertEqual(ChatTimestampFormatter.timeText(for: date("2026-07-05 22:15"), now: now, calendar: calendar), "22:15")
        XCTAssertEqual(ChatTimestampFormatter.timeText(for: date("2026-06-30 08:05"), now: now, calendar: calendar), "08:05")
    }

    func testDaySeparatorTextUsesTodayYesterdayThenDate() {
        let now = date("2026-07-06 15:00")
        XCTAssertEqual(ChatTimestampFormatter.daySeparatorText(for: date("2026-07-06 01:00"), now: now, calendar: calendar), "今日")
        XCTAssertEqual(ChatTimestampFormatter.daySeparatorText(for: date("2026-07-05 23:59"), now: now, calendar: calendar), "昨日")
        XCTAssertEqual(ChatTimestampFormatter.daySeparatorText(for: date("2026-07-04 10:00"), now: now, calendar: calendar), "7/4(土)")
    }

    func testStartsNewDayComparesCalendarDays() {
        XCTAssertTrue(ChatTimestampFormatter.startsNewDay(date("2026-07-06 00:01"), after: nil, calendar: calendar))
        XCTAssertTrue(ChatTimestampFormatter.startsNewDay(date("2026-07-06 00:01"), after: date("2026-07-05 23:59"), calendar: calendar))
        XCTAssertFalse(ChatTimestampFormatter.startsNewDay(date("2026-07-06 23:59"), after: date("2026-07-06 00:01"), calendar: calendar))
    }
}
