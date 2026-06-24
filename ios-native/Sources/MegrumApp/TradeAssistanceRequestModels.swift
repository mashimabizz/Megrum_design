import Foundation

enum TradeAssistanceRequestKind: String, CaseIterable, Identifiable, Sendable {
    case late
    case cancel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .late:
            "遅刻を申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var systemImage: String {
        switch self {
        case .late:
            "clock.badge.exclamationmark"
        case .cancel:
            "xmark.circle"
        }
    }

    var messagePrefix: String {
        switch self {
        case .late:
            "遅刻申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .late:
            "遅れる理由"
        case .cancel:
            "キャンセルが必要な理由"
        }
    }

    var notePlaceholder: String {
        switch self {
        case .late:
            "待ち合わせ場所への向かい方や到着見込みなど（任意）"
        case .cancel:
            "相手への補足や代替案など（任意）"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .late:
            "遅刻連絡が相手の判断材料になることを確認しました。"
        case .cancel:
            "キャンセル申請後も相手の確認が必要なことを確認しました。"
        }
    }

    var placeholder: String {
        reasonPlaceholder
    }

    var menuAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請を開く"
        case .cancel:
            "キャンセル申請を開く"
        }
    }

    var reasonAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻理由"
        case .cancel:
            "キャンセル理由"
        }
    }

    var noteAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の補足"
        case .cancel:
            "キャンセル申請の補足"
        }
    }

    var acknowledgementAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の確認事項"
        case .cancel:
            "キャンセル申請の確認事項"
        }
    }

    func systemMessageBody(from memo: String) -> String {
        let draft = TradeAssistanceRequestDraft(
            kind: self,
            reason: memo,
            acknowledgesImpact: true
        )
        return draft.systemIntent?.messageBody ?? messagePrefix
    }
}

enum TradeLateDelayBucket: Int, CaseIterable, Identifiable, Equatable, Sendable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .ten, .twenty, .thirty:
            "\(rawValue)分"
        case .sixty:
            "1時間"
        case .ninety:
            "1時間以上"
        }
    }

    var accessibilityLabel: String {
        "遅れる見込み \(title)"
    }
}

struct TradeAssistanceSystemIntent: Equatable, Sendable {
    enum Action: String, Equatable, Sendable {
        case lateNotice = "late_notice"
        case cancelRequested = "cancel_requested"
    }

    var kind: TradeAssistanceRequestKind
    var action: Action
    var delayBucket: TradeLateDelayBucket?
    var reason: String
    var note: String?
    var acknowledgedImpact: Bool

    var lateMinutes: Int? {
        delayBucket?.rawValue
    }

    var metadata: [String: String] {
        var values = [
            "action": action.rawValue,
            "reason": reason
        ]
        if let lateMinutes {
            values["late_minutes"] = "\(lateMinutes)"
        }
        if let note {
            values["note"] = note
        }
        return values
    }

    var messageBody: String {
        let noteSuffix = note.map { "\n\($0)" } ?? ""
        switch kind {
        case .late:
            let delay = delayBucket?.title ?? TradeLateDelayBucket.ten.title
            return "\(delay)遅れる旨が通知されました\n理由：\(reason)\(noteSuffix)"
        case .cancel:
            return "取引キャンセルが申請されました\n理由：\(reason)\(noteSuffix)"
        }
    }
}

struct TradeAssistanceRequestDraft: Equatable, Sendable {
    var kind: TradeAssistanceRequestKind
    var delayBucket: TradeLateDelayBucket = .ten
    var reason: String = ""
    var note: String = ""
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String? {
        note.nilIfBlank
    }

    var isSubmittable: Bool {
        !normalizedReason.isEmpty && acknowledgesImpact
    }

    var systemIntent: TradeAssistanceSystemIntent? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .late:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .lateNotice,
                delayBucket: delayBucket,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        case .cancel:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .cancelRequested,
                delayBucket: nil,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        }
    }
}
