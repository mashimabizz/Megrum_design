import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeLocalDateDetail: Codable, Equatable, Sendable {
    var prefecture: String
    var memo: String
}
struct HomeExchangeEditingDate: Identifiable, Equatable {
    var dateKeys: [String]

    var id: String {
        dateKeys.joined(separator: ",")
    }
}

enum HomeExchangeListingConditionReflector {
    static let multipleMemoText = "複数の個別募集に紐づくため個別募集を参照ください"

    static func reflectedDetails(
        from listings: [IndividualListing],
        calendar: Calendar = HomeExchangeCalendarFactory.calendar,
        now: Date = Date()
    ) -> [String: HomeExchangeLocalDateDetail] {
        let groupedDetails = listings.reduce(into: [String: [HomeExchangeLocalDateDetail]]()) { result, listing in
            guard listing.status == .active,
                  let summary = IndividualListingExchangeSummary.extract(from: listing.note).summary,
                  summary.includesLocal
            else {
                return
            }

            let keys = dateKeys(from: summary.localSchedule, calendar: calendar, now: now)
            guard !keys.isEmpty else {
                return
            }

            let detail = HomeExchangeLocalDateDetail(
                prefecture: summary.localPrefecture.trimmingCharacters(in: .whitespacesAndNewlines),
                memo: summary.localPlaceMemo.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            keys.forEach { key in
                result[key, default: []].append(detail)
            }
        }

        return groupedDetails.mapValues(mergeDetails)
    }

    private static func mergeDetails(_ details: [HomeExchangeLocalDateDetail]) -> HomeExchangeLocalDateDetail {
        let prefectures = orderedUnique(details.compactMap { $0.prefecture.nilIfBlank })
        let memos = orderedUnique(details.compactMap { $0.memo.nilIfBlank })

        return HomeExchangeLocalDateDetail(
            prefecture: prefectures.first ?? "",
            memo: memos.count > 1 ? multipleMemoText : memos.first ?? ""
        )
    }

    private static func dateKeys(from schedule: String, calendar: Calendar, now: Date) -> [String] {
        let normalized = schedule
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "　", with: " ")
        guard !normalized.isEmpty,
              normalized != IndividualListingExchangeSummary.defaultLocalSchedule
        else {
            return []
        }

        let patterns = [
            #"(?<month>\d{1,2})月(?<day>\d{1,2})日"#,
            #"(?<month>\d{1,2})/(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})\.(?<day>\d{1,2})"#
        ]
        let currentYear = calendar.component(.year, from: now)
        let keys = patterns.flatMap { pattern in
            matchedDateKeys(in: normalized, pattern: pattern, year: currentYear, calendar: calendar)
        }
        return HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: keys))
    }

    private static func matchedDateKeys(
        in text: String,
        pattern: String,
        year: Int,
        calendar: Calendar
    ) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let monthRange = Range(match.range(withName: "month"), in: text),
                  let dayRange = Range(match.range(withName: "day"), in: text),
                  let month = Int(text[monthRange]),
                  let day = Int(text[dayRange]),
                  let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
            else {
                return nil
            }
            return HomeExchangeDateKey.key(for: date, calendar: calendar)
        }
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }
}

enum HomeExchangeCalendarFactory {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }
}

enum HomeExchangeLocalDateDetailCodec {
    static func decode(_ rawValue: String) -> [String: HomeExchangeLocalDateDetail] {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: HomeExchangeLocalDateDetail].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func encode(_ details: [String: HomeExchangeLocalDateDetail]) -> String {
        guard let data = try? JSONEncoder().encode(details),
              let rawValue = String(data: data, encoding: .utf8) else {
            return ""
        }
        return rawValue
    }
}

struct HomeExchangeCalendarLegendEntry: Identifiable {
    var title: String
    var color: Color

    var id: String { title }
}

struct HomeExchangeCalendarDay: Equatable, Identifiable {
    var date: Date
    var key: String
    var isInDisplayedMonth: Bool
    var weekdaySymbol: String
    var dayNumber: Int
    var monthNumber: Int

    var id: String { key }
}

enum HomeExchangeCalendarMonthBuilder {
    static let weekdaySymbols = ["月", "火", "水", "木", "金", "土", "日"]

    static func monthStart(containing date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        if let start = calendar.date(from: components) {
            return calendar.startOfDay(for: start)
        }
        return calendar.startOfDay(for: date)
    }

    static func weeks(containing month: Date, calendar: Calendar = .current) -> [[HomeExchangeCalendarDay]] {
        let monthStart = monthStart(containing: month, calendar: calendar)
        let leadingDays = leadingDayCount(for: monthStart, calendar: calendar)
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        let displayedMonth = calendar.component(.month, from: monthStart)

        let days = (0..<42).compactMap { offset -> HomeExchangeCalendarDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let weekdayIndex = mondayFirstWeekdayIndex(for: date, calendar: calendar)
            return HomeExchangeCalendarDay(
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

    private static func leadingDayCount(for monthStart: Date, calendar: Calendar) -> Int {
        mondayFirstWeekdayIndex(for: monthStart, calendar: calendar)
    }

    private static func mondayFirstWeekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

enum HomeExchangePrefecturePresentation {
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
