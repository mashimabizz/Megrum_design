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

    /// 任意の (開始, 終了) ペアから、期間内の日付キーを列挙する（打診フローの相手カレンダー用）。
    static func localDateKeys(fromStartEndPairs pairs: [(start: Date, end: Date)]) -> [String] {
        pairs.flatMap { dateKeys(from: $0.start, through: $0.end) }
    }

    /// 自分と相手のAWが重なっている組のうち、最初に見つかった会場名。
    /// 相手側の会場名を優先し、無ければ自分側を使う。
    static func matchedVenue(
        viewerWindows: [SupabaseHomeActivityWindowRow],
        partnerWindows: [SupabaseHomeActivityWindowRow]
    ) -> String? {
        for viewerWindow in viewerWindows {
            for partnerWindow in partnerWindows where windowsOverlap(viewerWindow, partnerWindow) {
                if let venue = trimmed(partnerWindow.venue ?? "") ?? trimmed(viewerWindow.venue ?? "") {
                    return venue
                }
            }
        }
        return nil
    }

    /// 自分と相手の両方が現地予定を持つ日付キー（結論一文の日付表示用）。
    static func matchedLocalDateKeys(
        viewerWindows: [SupabaseHomeActivityWindowRow],
        partnerWindows: [SupabaseHomeActivityWindowRow]
    ) -> Set<String> {
        localDateKeys(from: viewerWindows).intersection(localDateKeys(from: partnerWindows))
    }

    /// 都道府県名の表示用短縮（東京都→東京、大阪府→大阪、神奈川県→神奈川。
    /// 北海道はそのまま）。
    static func shortPrefectureName(_ name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName != "北海道", trimmedName.count > 1 else {
            return trimmedName
        }
        if let last = trimmedName.last, ["都", "府", "県"].contains(String(last)) {
            return String(trimmedName.dropLast())
        }
        return trimmedName
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
