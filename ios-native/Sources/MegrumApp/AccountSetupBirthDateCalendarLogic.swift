import Foundation

struct AccountSetupBirthDateCalendarDay: Identifiable, Equatable {
    var id: String
    var date: Date?
}

enum AccountSetupBirthDateCalendarLogic {
    static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    static func startOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func days(for month: Date) -> [AccountSetupBirthDateCalendarDay] {
        let start = startOfMonth(month)
        guard let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }

        let leadingBlankCount = max(0, calendar.component(.weekday, from: start) - 1)
        var days = (0..<leadingBlankCount).map { index in
            AccountSetupBirthDateCalendarDay(id: "blank-leading-\(index)", date: nil)
        }

        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            guard let date = calendar.date(from: components) else {
                continue
            }
            days.append(AccountSetupBirthDateCalendarDay(id: isoDateString(from: date), date: date))
        }

        let trailingBlankCount = (7 - (days.count % 7)) % 7
        days.append(contentsOf: (0..<trailingBlankCount).map { index in
            AccountSetupBirthDateCalendarDay(id: "blank-trailing-\(index)", date: nil)
        })
        return days
    }

    static func addMonths(_ value: Int, to month: Date) -> Date? {
        calendar.date(byAdding: .month, value: value, to: startOfMonth(month))
    }

    static func addYears(_ value: Int, to month: Date, maxDate: Date, minimumYear: Int = 1900) -> Date? {
        let start = startOfMonth(month)
        let components = calendar.dateComponents([.year, .month], from: start)
        guard
            let currentYear = components.year,
            let currentMonth = components.month
        else {
            return nil
        }

        let targetYear = currentYear + value
        guard targetYear >= minimumYear else {
            return nil
        }

        guard let targetMonth = calendar.date(from: DateComponents(year: targetYear, month: currentMonth, day: 1)) else {
            return nil
        }

        return isAfterMonth(targetMonth, maxDate) ? nil : targetMonth
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isAfter(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.startOfDay(for: lhs) > calendar.startOfDay(for: rhs)
    }

    static func isAfterMonth(_ month: Date, _ maxDate: Date) -> Bool {
        startOfMonth(month) > startOfMonth(maxDate)
    }

    static func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func monthTitle(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func accessibilityLabel(for date: Date) -> String {
        accessibilityFormatter.string(from: date)
    }

    private static func isoDateString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        return formatter
    }()

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
