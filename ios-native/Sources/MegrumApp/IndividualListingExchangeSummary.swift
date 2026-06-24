import Foundation

struct IndividualListingExchangeSummary: Equatable {
    static let defaultLocalSchedule = "相談して決める"

    var handoffMethod: IndividualListingHandoffDraft
    var localPrefecture: String
    var localPlaceMemo: String
    var localSchedule: String
    var shippingFee: IndividualListingShippingFeeDraft
    var shippingDays: IndividualListingShippingDaysDraft
    var acceptsOutsideCondition: Bool

    init(
        handoffMethod: IndividualListingHandoffDraft = .both,
        localPrefecture: String = "東京都",
        localPlaceMemo: String = "",
        localSchedule: String = Self.defaultLocalSchedule,
        shippingFee: IndividualListingShippingFeeDraft = .negotiate,
        shippingDays: IndividualListingShippingDaysDraft = .twoToFourDays,
        acceptsOutsideCondition: Bool = true
    ) {
        self.handoffMethod = handoffMethod
        self.localPrefecture = localPrefecture
        self.localPlaceMemo = localPlaceMemo
        self.localSchedule = localSchedule
        self.shippingFee = shippingFee
        self.shippingDays = shippingDays
        self.acceptsOutsideCondition = acceptsOutsideCondition
    }

    var includesLocal: Bool {
        handoffMethod != .mail
    }

    var includesMail: Bool {
        handoffMethod != .local
    }

    var storageLine: String {
        var parts = ["交換手段: \(handoffMethod.title)"]
        if includesLocal {
            parts.append("都道府県: \(normalized(localPrefecture, fallback: "未設定"))")
            parts.append("場所メモ: \(normalized(localPlaceMemo, fallback: "相談"))")
            parts.append("日程: \(normalized(localSchedule, fallback: Self.defaultLocalSchedule))")
        }
        if includesMail {
            parts.append("送料: \(shippingFee.title)")
            parts.append("発送目安: \(shippingDays.title)")
        }
        parts.append("条件外打診: \(acceptsOutsideCondition ? "可" : "不可")")
        return parts.joined(separator: " / ")
    }

    var localDetailText: String? {
        guard includesLocal else {
            return nil
        }
        let place = normalized(localPlaceMemo, fallback: "場所相談")
        return "\(normalized(localPrefecture, fallback: "未設定")) / \(place) / \(normalized(localSchedule, fallback: Self.defaultLocalSchedule))"
    }

    var localDetailTextForProposalDisplay: String? {
        guard includesLocal else {
            return nil
        }
        return [
            normalized(localPrefecture, fallback: "未設定"),
            localPlaceMemo.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
            normalized(localSchedule, fallback: Self.defaultLocalSchedule)
        ]
        .compactMap(\.self)
        .joined(separator: " / ")
    }

    var mailDetailText: String? {
        guard includesMail else {
            return nil
        }
        return "送料 \(shippingFee.title) / 発送 \(shippingDays.title)"
    }

    static func extract(from note: String?) -> (summary: IndividualListingExchangeSummary?, remainingNote: String?) {
        guard let note else {
            return (nil, nil)
        }
        let lines = note
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let summaryIndex = lines.firstIndex(where: { isSummaryLine($0) }) else {
            let remaining = note.trimmingCharacters(in: .whitespacesAndNewlines)
            return (nil, remaining.isEmpty ? nil : remaining)
        }
        let summary = parse(lines[summaryIndex])
        let remainingLines = lines
            .enumerated()
            .filter { $0.offset != summaryIndex && !$0.element.isEmpty }
            .map(\.element)
        let remaining = remainingLines.joined(separator: "\n")
        return (summary, remaining.isEmpty ? nil : remaining)
    }

    private static func isSummaryLine(_ line: String) -> Bool {
        line.contains("交換手段:") && line.contains("条件外打診:")
    }

    private static func parse(_ line: String) -> IndividualListingExchangeSummary? {
        let tokens = line
            .components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        func value(for prefix: String) -> String? {
            tokens
                .first { $0.hasPrefix(prefix) }?
                .dropFirst(prefix.count)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let methodTitle = value(for: "交換手段:"),
              let method = IndividualListingHandoffDraft.method(fromTitle: methodTitle)
        else {
            return nil
        }

        return IndividualListingExchangeSummary(
            handoffMethod: method,
            localPrefecture: value(for: "都道府県:") ?? legacyLocalPrefecture(from: tokens) ?? "東京都",
            localPlaceMemo: restoredBlank(value(for: "場所メモ:"), blankMarkers: ["相談", "場所相談"]),
            localSchedule: value(for: "日程:") ?? Self.defaultLocalSchedule,
            shippingFee: IndividualListingShippingFeeDraft.allCases.first { $0.title == value(for: "送料:") } ?? .negotiate,
            shippingDays: IndividualListingShippingDaysDraft.allCases.first { $0.title == value(for: "発送目安:") } ?? .twoToFourDays,
            acceptsOutsideCondition: value(for: "条件外打診:") != "不可"
        )
    }

    private static func legacyLocalPrefecture(from tokens: [String]) -> String? {
        tokens
            .first { $0.hasPrefix("現地:") }?
            .dropFirst("現地:".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func restoredBlank(_ value: String?, blankMarkers: Set<String>) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !blankMarkers.contains(value)
        else {
            return ""
        }
        return value
    }

    private func normalized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private extension IndividualListingHandoffDraft {
    static func method(fromTitle title: String) -> IndividualListingHandoffDraft? {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return allCases.first { method in
            method.title == normalized || (method == .both && normalized == "どちらもOK")
        }
    }
}
