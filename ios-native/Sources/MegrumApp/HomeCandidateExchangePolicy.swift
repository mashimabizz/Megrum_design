import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateExchangePolicy {
    static func allowsMail(_ exchangeType: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: exchangeType) else {
            return false
        }
        return method == .mail || method == .both
    }

    static func allowsLocal(_ exchangeType: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: exchangeType) else {
            return true
        }
        return method == .hand || method == .both
    }

    static func methodTitle(from exchangeType: String?) -> String? {
        ExchangeMethod(exchangeTypeValue: exchangeType)?.displayName
    }

    static func methodTitle(allowsLocal: Bool, allowsMail: Bool) -> String? {
        switch (allowsLocal, allowsMail) {
        case (true, true):
            ExchangeMethod.both.displayName
        case (true, false):
            ExchangeMethod.hand.displayName
        case (false, true):
            ExchangeMethod.mail.displayName
        case (false, false):
            nil
        }
    }

    static func localConditionText(prefectures: [String], dateKeys: Set<String>) -> String? {
        let prefecture = orderedUnique(prefectures.compactMap(trimmed))
            .first
        let dateText = nearestLocalDateText(from: dateKeys)
        let parts = [prefecture, dateText].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    static func nearestLocalDateText(from dateKeys: Set<String>) -> String? {
        let usableKeys = orderedLocalDateKeys(from: dateKeys, onlyFuture: true)
        let displayKeys = usableKeys.isEmpty ? orderedLocalDateKeys(from: dateKeys, onlyFuture: false) : usableKeys
        guard let firstKey = displayKeys.first else {
            return nil
        }
        let suffix = displayKeys.count > 1 ? "他" : ""
        return "\(HomeExchangeDateKey.compactDisplayText(for: firstKey))\(suffix)"
    }

    static func activityWindowsOverlap(
        _ viewerWindows: [SupabaseHomeActivityWindowRow],
        _ partnerWindows: [SupabaseHomeActivityWindowRow]
    ) -> Bool {
        viewerWindows.contains { viewerWindow in
            partnerWindows.contains { partnerWindow in
                windowsOverlap(viewerWindow, partnerWindow)
            }
        }
    }

    static func localDateKeys(from windows: [SupabaseHomeActivityWindowRow]) -> Set<String> {
        Set(windows.flatMap { window in
            dateKeys(from: window.startAt, through: window.endAt)
        })
    }

    static func prefecturesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalizedArea(lhs),
              let rhs = normalizedArea(rhs)
        else {
            return false
        }
        return lhs == rhs
    }

    static func normalizedArea(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }

    private static func windowsOverlap(
        _ lhs: SupabaseHomeActivityWindowRow,
        _ rhs: SupabaseHomeActivityWindowRow
    ) -> Bool {
        lhs.startAt < rhs.endAt && rhs.startAt < lhs.endAt
    }

    private static func dateKeys(from startAt: Date, through endAt: Date, calendar: Calendar = .current) -> [String] {
        let startDay = calendar.startOfDay(for: startAt)
        let endDay = calendar.startOfDay(for: endAt)
        guard startDay <= endDay else {
            return [HomeExchangeDateKey.key(for: startAt, calendar: calendar)]
        }

        var keys: [String] = []
        var cursor = startDay
        while cursor <= endDay {
            keys.append(HomeExchangeDateKey.key(for: cursor, calendar: calendar))
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = nextDay
        }
        return keys
    }

    private static func orderedLocalDateKeys(from dateKeys: Set<String>, onlyFuture: Bool) -> [String] {
        dateKeys
            .filter { !onlyFuture || HomeExchangeDateKey.isOnOrAfterToday($0) }
            .compactMap { key -> (String, Date)? in
                guard let date = HomeExchangeDateKey.date(from: key) else {
                    return nil
                }
                return (key, date)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private static func trimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
