import Foundation
import MegrumCore

/// 相手候補シートの「この人とどう交換できそう？」行のバッジ段階。
enum ConditionVerdictBadge: Equatable, Sendable {
    case ok        // 両者一致・確定
    case needsTalk // 要相談（片方未設定・要調整）
    case check     // 要確認（噛み合わない）
}

/// 一部だけ太字にできるテキスト断片（銀行名の同一銀行太字用）。
struct VerdictTextSegment: Equatable, Sendable {
    var text: String
    var bold: Bool

    init(_ text: String, bold: Bool = false) {
        self.text = text
        self.bold = bold
    }
}

struct ConditionVerdictLine: Equatable, Sendable, Identifiable {
    enum Kind: String, Equatable, Sendable {
        case local
        case mail
        case payment
    }

    var id: String { kind.rawValue }
    var kind: Kind
    var iconSystemName: String
    var segments: [VerdictTextSegment]
    var subtitle: String?
    var badge: ConditionVerdictBadge
    var showsCalendarButton: Bool

    var plainText: String {
        segments.map(\.text).joined()
    }
}

struct HomeConditionVerdict: Equatable, Sendable {
    var lines: [ConditionVerdictLine]

    var isEmpty: Bool { lines.isEmpty }
}

enum HomeConditionVerdictPolicy {
    static func make(
        from signals: HomeCandidateConditionSignals,
        partnerPaymentNote: String? = nil
    ) -> HomeConditionVerdict {
        var lines: [ConditionVerdictLine] = []
        if let local = localLine(signals.exchange) {
            lines.append(local)
        }
        if let mail = mailLine(signals.exchange) {
            lines.append(mail)
        }
        if let payment = paymentLine(signals.payment, partnerNote: partnerPaymentNote) {
            lines.append(payment)
        }
        return HomeConditionVerdict(lines: lines)
    }

    // MARK: - 現地

    private static func localLine(_ exchange: HomeExchangeConditionSignals) -> ConditionVerdictLine? {
        guard exchange.localExchangeSelected else {
            return nil
        }

        let partnerPref = displayPrefecture(from: exchange.partnerLocalPrefectures)
        let place = exchange.matchedVenue ?? partnerPref
        let dates = orderedFutureDates(from: exchange.matchedLocalDateKeys)
        let hasPlace = exchange.prefectureMatches && place != nil
        let hasDate = !dates.isEmpty

        let text: String
        let badge: ConditionVerdictBadge
        var subtitle: String?

        if hasPlace, hasDate, let place {
            text = "\(place)で\(datesText(dates))に会える"
            badge = .ok
        } else if hasPlace, let place {
            text = "\(place)で会える／会う日は取引成立までに決める"
            badge = .needsTalk
        } else if hasDate {
            text = "\(datesText(dates))に会える／会う場所は取引成立までに決める"
            badge = .needsTalk
        } else if exchange.prefectureUnset {
            text = "会う場所は取引成立までに決める"
            badge = .needsTalk
            if let partnerPref {
                subtitle = "相手: \(partnerPref)"
            }
        } else {
            text = "会う場所と日は取引成立までに決める"
            badge = .needsTalk
        }

        return ConditionVerdictLine(
            kind: .local,
            iconSystemName: "mappin.and.ellipse",
            segments: [VerdictTextSegment(text)],
            subtitle: subtitle,
            badge: badge,
            showsCalendarButton: true
        )
    }

    // MARK: - 郵送

    private static func mailLine(_ exchange: HomeExchangeConditionSignals) -> ConditionVerdictLine? {
        guard exchange.postalAcceptedByBoth else {
            return nil
        }
        // 送料が「自己負担」と分かっている時だけOK。不明・要相談は安全側で「取引成立までに決める」。
        let isSelfBear = exchange.partnerShippingFeeTitle?.contains("自己負担") == true
        let needsTalk = exchange.shippingFeeNeedsDiscussion || !isSelfBear
        let feeText = needsTalk ? "送料は取引成立までに決める" : "互いに送料を負担"
        let subtitle: String
        if let days = exchange.partnerShippingDaysTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !days.isEmpty {
            subtitle = "\(feeText) ・ \(days)に発送"
        } else {
            subtitle = feeText
        }
        return ConditionVerdictLine(
            kind: .mail,
            iconSystemName: "shippingbox",
            segments: [VerdictTextSegment("郵送でもOK")],
            subtitle: subtitle,
            badge: needsTalk ? .needsTalk : .ok,
            showsCalendarButton: false
        )
    }

    // MARK: - お金

    private static func paymentLine(
        _ payment: HomePaymentConditionSignals,
        partnerNote: String?
    ) -> ConditionVerdictLine? {
        guard payment.status != .skipped else {
            return nil
        }

        let segments: [VerdictTextSegment]
        var subtitle: String?
        let badge: ConditionVerdictBadge

        switch payment.status {
        case .skipped:
            return nil
        case .compatible:
            let shared = sharedMethods(payment)
            segments = methodListSegments(shared, payment: payment, note: partnerNote)
                + [VerdictTextSegment("がお互い共通")]
            badge = .ok
        case .viewerUnset:
            segments = [VerdictTextSegment("相手は ")]
                + methodListSegments(payment.partnerMethods, payment: payment, note: partnerNote)
                + [VerdictTextSegment(" でOK")]
            subtitle = "あなたの支払い方法を決めれば打診できます"
            badge = .needsTalk
        case .partnerUnset:
            segments = [VerdictTextSegment("相手の支払い方法は未設定")]
            subtitle = "あなたは \(methodListText(payment.viewerMethods)) 対応。打診で相談できます"
            badge = .needsTalk
        case .unset:
            segments = [VerdictTextSegment("支払い方法は取引成立までに決める")]
            badge = .needsTalk
        case .needsDiscussion:
            segments = [VerdictTextSegment("相手は ")]
                + methodListSegments(payment.partnerMethods, payment: payment, note: partnerNote)
            subtitle = "打診で相談できます"
            badge = .needsTalk
        case .methodMismatch:
            segments = [VerdictTextSegment("相手は ")]
                + methodListSegments(payment.partnerMethods, payment: payment, note: partnerNote)
                + [VerdictTextSegment(" のみ")]
            subtitle = "あなたの方法と違うので打診で相談"
            badge = .check
        }

        return ConditionVerdictLine(
            kind: .payment,
            iconSystemName: "yensign.circle",
            segments: segments,
            subtitle: subtitle,
            badge: badge,
            showsCalendarButton: false
        )
    }

    // MARK: - 支払い方法ラベル

    private static func sharedMethods(_ payment: HomePaymentConditionSignals) -> [UserPaymentMethod] {
        let partnerSet = Set(payment.partnerMethods)
        return payment.viewerMethods.filter { $0 != .other && partnerSet.contains($0) }
    }

    private static func methodListSegments(
        _ methods: [UserPaymentMethod],
        payment: HomePaymentConditionSignals,
        note: String?
    ) -> [VerdictTextSegment] {
        let ordered = UserPaymentMethod.normalized(methods)
        guard !ordered.isEmpty else {
            return [VerdictTextSegment("支払い方法")]
        }
        var result: [VerdictTextSegment] = []
        for (index, method) in ordered.enumerated() {
            if index > 0 {
                result.append(VerdictTextSegment("・"))
            }
            result.append(contentsOf: methodSegments(method, payment: payment, note: note))
        }
        return result
    }

    private static func methodListText(_ methods: [UserPaymentMethod]) -> String {
        let ordered = UserPaymentMethod.normalized(methods)
        guard !ordered.isEmpty else {
            return "支払い方法"
        }
        return ordered.map(methodPlainLabel).joined(separator: "・")
    }

    private static func methodSegments(
        _ method: UserPaymentMethod,
        payment: HomePaymentConditionSignals,
        note: String?
    ) -> [VerdictTextSegment] {
        switch method {
        case .bankTransfer:
            guard !payment.partnerBankNames.isEmpty else {
                return [VerdictTextSegment("銀行振込")]
            }
            let sharedKeys = payment.sharedBankMatchKeys
            var segs = [VerdictTextSegment("銀行振込（")]
            for (index, name) in payment.partnerBankNames.enumerated() {
                if index > 0 {
                    segs.append(VerdictTextSegment("・"))
                }
                let isShared = BankMaster.matchKey(displayName: name).map { sharedKeys.contains($0) } ?? false
                segs.append(VerdictTextSegment(name, bold: isShared))
            }
            segs.append(VerdictTextSegment("）"))
            return segs
        case .paypay:
            return [VerdictTextSegment("PayPay")]
        case .cashExchange:
            return [VerdictTextSegment("現金の手渡し")]
        case .other:
            if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                return [VerdictTextSegment("その他（\(note)）")]
            }
            return [VerdictTextSegment("その他の方法")]
        }
    }

    private static func methodPlainLabel(_ method: UserPaymentMethod) -> String {
        switch method {
        case .bankTransfer:
            "銀行振込"
        case .paypay:
            "PayPay"
        case .cashExchange:
            "現金の手渡し"
        case .other:
            "その他の方法"
        }
    }

    // MARK: - 日付・都道府県ヘルパー

    private static func datesText(_ dates: [String]) -> String {
        switch dates.count {
        case 0:
            return ""
        case 1:
            return dates[0]
        case 2:
            return "\(dates[0])・\(dates[1])"
        default:
            return "\(dates[0])ほか\(dates.count - 1)日"
        }
    }

    private static func orderedFutureDates(from dateKeys: Set<String>) -> [String] {
        dateKeys
            .filter { HomeExchangeDateKey.isOnOrAfterToday($0) }
            .compactMap { key -> (String, Date)? in
                guard let date = HomeExchangeDateKey.date(from: key) else {
                    return nil
                }
                return (key, date)
            }
            .sorted { $0.1 < $1.1 }
            .map { HomeExchangeDateKey.compactDisplayText(for: $0.0) }
    }

    private static func displayPrefecture(from prefectures: Set<String>) -> String? {
        prefectures
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
            .first
    }
}
