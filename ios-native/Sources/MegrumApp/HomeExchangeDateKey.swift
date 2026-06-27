import Foundation

struct HomeExchangeDateKey: Equatable, Hashable, Sendable {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            return nil
        }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func normalizedKeys(from rawValue: String) -> [String] {
        orderedUnique(
            rawValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        .sorted()
    }

    static func rawValue(from keys: some Sequence<String>) -> String {
        orderedUnique(keys.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: ",")
    }

    static func isOnOrAfterToday(_ key: String, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let date = date(from: key, calendar: calendar) else {
            return false
        }
        return calendar.startOfDay(for: date) >= calendar.startOfDay(for: now)
    }

    static func displayText(for key: String, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar) else {
            return key
        }
        return date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .weekday(.abbreviated)
        )
    }

    static func compactDisplayText(for key: String, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar) else {
            return key
        }
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return key
        }
        return "\(month)/\(day)"
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
