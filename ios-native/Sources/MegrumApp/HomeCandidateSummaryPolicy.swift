import Foundation

/// ホーム候補カードの「強タグ（1個）」語彙。iter1226.272 で確定した仕様。
/// トーンは exact＝グラデ塗り／possible＝枠線／discuss＝淡スカイ。
enum HomeCandidateStrongTag: String, Equatable, Sendable {
    case perfect
    case designated
    case meetable
    case postalOK
    case wishMatch
    case discuss

    var title: String {
        switch self {
        case .perfect: "ぴったり"
        case .designated: "指名あり"
        case .meetable: "会えそう"
        case .postalOK: "郵送OK"
        case .wishMatch: "wish一致"
        case .discuss: "要相談"
        }
    }

    var tone: HomeCandidateStrongTagTone {
        switch self {
        case .perfect, .designated: .exact
        case .meetable, .postalOK, .wishMatch: .possible
        case .discuss: .discuss
        }
    }
}

enum HomeCandidateStrongTagTone: Equatable, Sendable {
    case exact
    case possible
    case discuss
}

/// 強タグ・成立しやすさランク・結論一文を signals から生成する純粋ロジック。
enum HomeCandidateSummaryPolicy {
    static let maxSummaryLength = 38

    // MARK: - ランクと強タグ

    /// 成立しやすさランク。4=ぴったり、3=指名あり、2=会えそう/郵送OK、
    /// 1=wish一致、0=要相談。ソートと代表グッズ選定に使う。
    static func rank(for signals: HomeCandidateConditionSignals) -> Int {
        let goods = HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods)
        let exchange = HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange)
        let payment = HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment)

        if goods == .direct && exchange == .exact && (payment == .exact || payment == .compatible) {
            return 4
        }
        if goods == .direct {
            return 3
        }
        if exchange == .exact {
            return 2
        }
        if goods == .wish {
            return 1
        }
        return 0
    }

    static func strongTag(for signals: HomeCandidateConditionSignals) -> HomeCandidateStrongTag {
        switch rank(for: signals) {
        case 4:
            return .perfect
        case 3:
            return .designated
        case 2:
            return isLocalExact(signals.exchange) ? .meetable : .postalOK
        case 1:
            return .wishMatch
        default:
            return .discuss
        }
    }

    // MARK: - 塊のソートと代表グッズ

    /// 塊のソートキー：①ランク2以上のグッズ数（降順）→②塊内最大ランク（降順）。
    /// 同点は呼び出し側の従来順を維持する（stable sort 前提）。
    static func sortKey(for candidate: HomeDiscoveryCandidate) -> (Int, Int) {
        let ranks = goodsRanks(of: candidate)
        let easyCount = ranks.filter { $0 >= 2 }.count
        let bestRank = ranks.max() ?? 0
        return (easyCount, bestRank)
    }

    static func sortedCandidates(_ candidates: [HomeDiscoveryCandidate]) -> [HomeDiscoveryCandidate] {
        candidates
            .enumerated()
            .sorted { lhs, rhs in
                let lhsKey = sortKey(for: lhs.element)
                let rhsKey = sortKey(for: rhs.element)
                if lhsKey == rhsKey {
                    return lhs.offset < rhs.offset
                }
                return lhsKey > rhsKey
            }
            .map(\.element)
    }

    /// 塊内のグッズをランク降順（同点は従来順）に並べ替える。先頭が代表グッズ。
    static func orderedGoodsByRank(of candidate: HomeDiscoveryCandidate) -> [HomeMockGoods] {
        candidate.goods
            .enumerated()
            .sorted { lhs, rhs in
                let lhsRank = rank(for: candidate.conditionSignals(for: lhs.element))
                let rhsRank = rank(for: candidate.conditionSignals(for: rhs.element))
                if lhsRank == rhsRank {
                    return lhs.offset < rhs.offset
                }
                return lhsRank > rhsRank
            }
            .map(\.element)
    }

    private static func goodsRanks(of candidate: HomeDiscoveryCandidate) -> [Int] {
        guard !candidate.goods.isEmpty else {
            return [rank(for: candidate.signals)]
        }
        return candidate.goods.map { goods in
            rank(for: candidate.conditionSignals(for: goods))
        }
    }

    // MARK: - 結論一文

    /// 結論一文：「節A（グッズ）・節B（交換）」最大2節。要相談時は最も軽い
    /// 相談ポイント1個＋相手の実値。38字超過時は括弧（相手: …）を先に落とす。
    static func summaryText(for signals: HomeCandidateConditionSignals) -> String {
        let full = assembledSummary(for: signals, includesPartnerContext: true)
        if full.count <= maxSummaryLength {
            return full
        }
        let compact = assembledSummary(for: signals, includesPartnerContext: false)
        return compact
    }

    private static func assembledSummary(
        for signals: HomeCandidateConditionSignals,
        includesPartnerContext: Bool
    ) -> String {
        let parts = [
            goodsClause(for: signals),
            secondaryClause(for: signals, includesPartnerContext: includesPartnerContext)
        ].compactMap { $0 }

        if parts.isEmpty {
            return "同じ推しのグッズ・条件は打診で相談"
        }
        return parts.joined(separator: "・")
    }

    private static func goodsClause(for signals: HomeCandidateConditionSignals) -> String? {
        switch HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) {
        case .direct:
            "あなたのグッズを指名中"
        case .wish:
            "あなたのウィッシュと一致"
        case .none:
            nil
        }
    }

    /// 節B：交換軸。ただしグッズ・交換が両方ポジティブで支払だけが課題の
    /// 時は支払の確認文に置き換える（支払unknownは文に出さない）。
    private static func secondaryClause(
        for signals: HomeCandidateConditionSignals,
        includesPartnerContext: Bool
    ) -> String? {
        let exchange = signals.exchange
        let exchangeIsExact = HomeDiscoveryMatchPolicy.exchangeCondition(for: exchange) == .exact

        if exchangeIsExact, signals.payment.status == .methodMismatch {
            return paymentMismatchClause(for: signals, includesPartnerContext: includesPartnerContext)
        }

        if isLocalExact(exchange) {
            return localExactClause(for: exchange)
        }
        if exchange.postalAcceptedByBoth {
            return exchange.shippingFeeNeedsDiscussion ? "郵送OK・送料は相談" : "郵送OK"
        }
        if exchange.localExchangeSelected {
            return localDiscussClause(for: exchange, includesPartnerContext: includesPartnerContext)
        }
        return "交換方法は打診で相談"
    }

    private static func localExactClause(for exchange: HomeExchangeConditionSignals) -> String {
        let place = exchange.matchedVenue ?? partnerPrefectureText(exchange)
        let date = HomeCandidateExchangePolicy.nearestLocalDateText(from: exchange.matchedLocalDateKeys)

        switch (place, date) {
        case let (place?, date?):
            return "\(place)で\(date)に会えそう"
        case let (place?, nil):
            return "\(place)で会えそう"
        case let (nil, date?):
            return "\(date)に会えそう"
        case (nil, nil):
            return "現地で会えそう"
        }
    }

    private static func localDiscussClause(
        for exchange: HomeExchangeConditionSignals,
        includesPartnerContext: Bool
    ) -> String {
        func partnerSuffix(_ value: String?) -> String {
            guard includesPartnerContext, let value, !value.isEmpty else {
                return ""
            }
            return "（相手: \(value)）"
        }

        if exchange.prefectureUnset {
            return "場所は打診で相談" + partnerSuffix(partnerPrefectureText(exchange))
        }
        if exchange.prefectureMatches && !exchange.dateMatches {
            let place = partnerPrefectureText(exchange).map { "\($0)で会える・" } ?? ""
            let partnerDate = HomeCandidateExchangePolicy.nearestLocalDateText(from: exchange.partnerLocalDateKeys)
            return place + "日程は相談" + partnerSuffix(partnerDate)
        }
        if !exchange.prefectureMatches && exchange.dateMatches {
            let dateText = HomeCandidateExchangePolicy.nearestLocalDateText(from: exchange.matchedLocalDateKeys)
            let datePrefix = dateText.map { "\($0)に会える・" } ?? ""
            return datePrefix + "場所は相談" + partnerSuffix(partnerPrefectureText(exchange))
        }
        return "場所と日程は相談" + partnerSuffix(exchange.partnerLocalConditionText)
    }

    private static func paymentMismatchClause(
        for signals: HomeCandidateConditionSignals,
        includesPartnerContext: Bool
    ) -> String {
        guard includesPartnerContext, let method = signals.payment.partnerMethods.first else {
            return "支払い方法だけ確認"
        }
        return "支払い方法だけ確認（相手: \(method.displayName)）"
    }

    // MARK: - Helpers

    private static func isLocalExact(_ exchange: HomeExchangeConditionSignals) -> Bool {
        exchange.localExchangeSelected
            && exchange.prefectureMatches
            && exchange.dateMatches
            && !exchange.prefectureUnset
    }

    private static func partnerPrefectureText(_ exchange: HomeExchangeConditionSignals) -> String? {
        guard let prefecture = exchange.partnerLocalPrefectures.sorted().first else {
            return nil
        }
        return HomeCandidateExchangePolicy.shortPrefectureName(prefecture)
    }
}
