import Foundation
import MegrumCore

struct TradeExchangeConditionSummary: Equatable {
    var text: String?
    var iconSystemName: String

    static func make(for proposal: TradeProposal, calendar: Calendar = .current) -> Self {
        let localText = localConditionText(for: proposal, calendar: calendar)
        let mailText = mailConditionText(for: proposal)

        switch proposal.exchangeMethod {
        case .hand:
            return TradeExchangeConditionSummary(
                text: localText,
                iconSystemName: "mappin.circle"
            )
        case .mail:
            return TradeExchangeConditionSummary(
                text: mailText,
                iconSystemName: "shippingbox.circle"
            )
        case .both:
            return TradeExchangeConditionSummary(
                text: [localText, mailText].compactMap { $0 }.joined(separator: "\n"),
                iconSystemName: "arrow.left.arrow.right.circle"
            )
        }
    }

    private static func localConditionText(for proposal: TradeProposal, calendar: Calendar) -> String? {
        if let candidate = proposal.meetupCandidates?.first(where: \.isValid) {
            guard let place = candidate.normalizedPlaceName.nilIfBlank else {
                return nil
            }
            let components = calendar.dateComponents([.month, .day], from: candidate.startAt)
            let day = components.month.flatMap { month in
                components.day.map { day in "\(month)月\(day)日" }
            } ?? "日程相談"
            let additional = max(0, (proposal.meetupCandidates ?? []).filter(\.isValid).count - 1)
            let suffix = additional > 0 ? " / 他\(additional)件" : ""
            return "現地: \(place) / \(day)\(suffix)"
        }

        if let summary = conditionValue(in: proposal.conditionTags, prefixes: ["待ち合わせ:", "現地:"]) {
            let parts = rawSummaryParts(summary)
            guard let prefecture = visibleLocalPrefecture(parts.first) else {
                return nil
            }
            let memo = parts.count >= 3 ? visibleLocalMemo(parts[1]) : nil
            let scheduleSource = parts.count >= 3 ? parts[2] : parts.dropFirst().first
            let components = [prefecture, memo, localScheduleText(scheduleSource)].compactMap { $0 }
            return "現地: \(components.joined(separator: " / "))"
        }

        return nil
    }

    private static func mailConditionText(for proposal: TradeProposal) -> String {
        let fee = conditionValue(in: proposal.conditionTags, prefixes: ["送料:", "送料 "])
            .map { cleanedValue($0, prefixes: ["送料"]) }
            ?? "要相談"
        let days = conditionValue(in: proposal.conditionTags, prefixes: ["発送目安:", "発送目安 ", "発送 "])
            .map { cleanedValue($0, prefixes: ["発送目安", "発送"]) }
            ?? "相談"
        return "郵送: 送料 \(fee) / 発送目安 \(days)"
    }

    private static func conditionValue(in tags: [String], prefixes: [String]) -> String? {
        for tag in tags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            for prefix in prefixes where trimmed.hasPrefix(prefix) {
                let value = String(trimmed.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }

    private static func rawSummaryParts(_ text: String) -> [String] {
        text.components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func visibleLocalPrefecture(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !["未設定", "対象外", "相談", "場所相談"].contains(value)
        else {
            return nil
        }
        return value
    }

    private static func visibleLocalMemo(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !["未設定", "対象外"].contains(value)
        else {
            return nil
        }
        return value
    }

    private static func localScheduleText(_ value: String?) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !["未設定", "対象外"].contains(value)
        else {
            return "日程相談"
        }
        if ["相談", "相談して決める", "日程は相談", "日程相談"].contains(value) {
            return "日程相談"
        }
        return value
    }

    private static func cleanedValue(_ value: String, prefixes: [String]) -> String {
        var cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in prefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned.nilIfBlank ?? "要相談"
    }
}
