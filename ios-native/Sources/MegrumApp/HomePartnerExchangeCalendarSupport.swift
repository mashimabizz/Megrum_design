import Foundation
import MegrumDesign
import SwiftUI

enum HomePartnerExchangeCalendarTextParser {
    static func parse(_ text: String?) -> (prefecture: String?, memo: String?) {
        let parts = detailParts(from: text)
        let prefecture = parts.first(where: isPrefecture)
        let memo = parts.first { part in
            !isPrefecture(part) && !containsDate(part) && !isScheduleConsultation(part)
        }
        return (prefecture, memo)
    }

    static func dateKeys(in text: String?) -> Set<String> {
        guard let text else {
            return []
        }
        let calendar = HomePartnerExchangeCalendarMonthBuilder.calendar
        let currentYear = calendar.component(.year, from: Date())
        let patterns = [
            #"(?<year>\d{4})-(?<month>\d{1,2})-(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})月(?<day>\d{1,2})日"#,
            #"(?<month>\d{1,2})/(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})\.(?<day>\d{1,2})"#
        ]
        let keys = patterns.flatMap { pattern in
            matchedDateKeys(in: text, pattern: pattern, fallbackYear: currentYear, calendar: calendar)
        }
        return Set(HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: keys)))
    }

    private static func detailParts(from text: String?) -> [String] {
        guard let text else {
            return []
        }
        return text
            .replacingOccurrences(of: "現地交換：", with: "")
            .components(separatedBy: " / ")
            .flatMap { $0.components(separatedBy: "、") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func matchedDateKeys(
        in text: String,
        pattern: String,
        fallbackYear: Int,
        calendar: Calendar
    ) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            let year = intValue(named: "year", in: text, match: match) ?? fallbackYear
            guard let month = intValue(named: "month", in: text, match: match),
                  let day = intValue(named: "day", in: text, match: match),
                  let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
            else {
                return nil
            }
            return HomeExchangeDateKey.key(for: date, calendar: calendar)
        }
    }

    private static func intValue(named name: String, in text: String, match: NSTextCheckingResult) -> Int? {
        let range = match.range(withName: name)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: text)
        else {
            return nil
        }
        return Int(text[swiftRange])
    }

    private static func isPrefecture(_ value: String) -> Bool {
        JapanesePrefectureCatalog.all.contains(value)
    }

    private static func containsDate(_ value: String) -> Bool {
        !dateKeys(in: value).isEmpty || value.contains("他")
    }

    private static func isScheduleConsultation(_ value: String) -> Bool {
        ["相談", "相談して決める", "日程は相談", "日程相談", "場所相談"].contains(value)
    }
}

enum HomePartnerExchangeCalendarMonthBuilder {
    static let weekdaySymbols = ["月", "火", "水", "木", "金", "土", "日"]

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }

    static func monthStart(containing date: Date, calendar: Calendar = Self.calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func weeks(containing visibleMonth: Date, calendar: Calendar = Self.calendar) -> [[HomePartnerExchangeCalendarDay]] {
        let monthStart = monthStart(containing: visibleMonth, calendar: calendar)
        let leadingDays = mondayFirstWeekdayIndex(for: monthStart, calendar: calendar)
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        let displayedMonth = calendar.component(.month, from: monthStart)

        let days = (0..<42).compactMap { offset -> HomePartnerExchangeCalendarDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let weekdayIndex = mondayFirstWeekdayIndex(for: date, calendar: calendar)
            return HomePartnerExchangeCalendarDay(
                date: date,
                key: HomeExchangeDateKey.key(for: date, calendar: calendar),
                isInDisplayedMonth: calendar.component(.month, from: date) == displayedMonth,
                weekdaySymbol: weekdaySymbols[weekdayIndex],
                dayNumber: calendar.component(.day, from: date),
                monthNumber: calendar.component(.month, from: date)
            )
        }

        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private static func mondayFirstWeekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

struct HomePartnerExchangeCalendarDay: Equatable, Identifiable {
    var date: Date
    var key: String
    var isInDisplayedMonth: Bool
    var weekdaySymbol: String
    var dayNumber: Int
    var monthNumber: Int

    var id: String { key }
}

enum HomePartnerExchangePrefecturePresentation {
    static func shortName(_ prefecture: String) -> String {
        let trimmed = prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "北海道" {
            return trimmed
        }
        return trimmed
            .replacingOccurrences(of: "都", with: "")
            .replacingOccurrences(of: "府", with: "")
            .replacingOccurrences(of: "県", with: "")
    }

    static func color(for prefecture: String) -> Color {
        let trimmed = prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = JapanesePrefectureCatalog.all.firstIndex(of: trimmed) else {
            return MegrumTheme.lavender
        }
        let hue = Double((index * 7) % JapanesePrefectureCatalog.all.count) / Double(JapanesePrefectureCatalog.all.count)
        return Color(hue: hue, saturation: 0.44, brightness: 0.86)
    }
}
