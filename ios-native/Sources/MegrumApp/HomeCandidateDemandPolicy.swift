import Foundation

/// ホーム候補行v3「需要ファースト」の需要行。優先順位は
/// 激求（指名）＞求（条件一致）＞定価＞探し中＞相談（iter1226.292 で合意した仕様）。
/// 否定文は使わない。
enum HomeCandidateDemandLine: Equatable, Sendable {
    /// 相手があなたの具体グッズを指名（個別募集の「このグッズ」選択肢に合致）
    case hotDemand(goodsIDs: [UUID])
    /// あなたのグッズが相手の条件（条件選択肢・ほしいもの）に一致
    case demand(goodsIDs: [UUID])
    /// 定価交換の選択肢あり
    case cash(amount: Int?)
    /// 合致なしだが相手の探し物が分かる
    case lookingFor(text: String)
    /// 合致なしで相手の求めも不明
    case discuss

    var rank: Int {
        switch self {
        case .hotDemand: 4
        case .demand: 3
        case .cash: 2
        case .lookingFor: 1
        case .discuss: 0
        }
    }
}

/// 需要行・物流行・支払行と、需要基準の並び順を signals から生成する純粋ロジック。
enum HomeCandidateDemandPolicy {

    // MARK: - 需要行

    static func demandLine(for signals: HomeCandidateConditionSignals) -> HomeCandidateDemandLine {
        let options = signals.individualListingSelection?.wantedOptions ?? []

        let designatedIDs = orderedUnique(
            options.filter { $0.kind == .goods }.flatMap(\.matchingGoodsIDs)
        )
        if !designatedIDs.isEmpty {
            return .hotDemand(goodsIDs: designatedIDs)
        }

        let conditionMatchedIDs = orderedUnique(
            options.filter { $0.kind == .condition }.flatMap(\.matchingGoodsIDs)
                + signals.wishMatchedOfferGoodsIDs
        )
        if !conditionMatchedIDs.isEmpty {
            return .demand(goodsIDs: conditionMatchedIDs)
        }

        if let cashOption = options.first(where: { $0.kind == .cash }) {
            return .cash(amount: cashOption.cashAmount)
        }

        if let text = signals.partnerLookingForText {
            return .lookingFor(text: text)
        }
        return .discuss
    }

    static func demandRank(for signals: HomeCandidateConditionSignals) -> Int {
        demandLine(for: signals).rank
    }

    // MARK: - 物流行（会場×日付 > 県 > 郵送 > 相談）

    static func logisticsText(for signals: HomeCandidateConditionSignals) -> String {
        let exchange = signals.exchange
        let postalSuffix = exchange.postalAcceptedByBoth ? "・郵送OK" : ""

        if isLocalExact(exchange) {
            let place = exchange.matchedVenue ?? partnerPrefectureText(exchange)
            let date = HomeCandidateExchangePolicy.nearestLocalDateText(from: exchange.matchedLocalDateKeys)
            switch (place, date) {
            case let (place?, date?):
                return "\(place)で\(date)に会えそう" + postalSuffix
            case let (place?, nil):
                return "\(place)で会えそう" + postalSuffix
            case let (nil, date?):
                return "\(date)に会えそう" + postalSuffix
            case (nil, nil):
                return "現地で会えそう" + postalSuffix
            }
        }

        if exchange.localExchangeSelected, exchange.prefectureMatches, !exchange.prefectureUnset {
            let place = partnerPrefectureText(exchange).map { "\($0)で会えそう" } ?? "現地で会えそう"
            return place + postalSuffix
        }

        if exchange.postalAcceptedByBoth {
            return exchange.shippingFeeNeedsDiscussion ? "郵送OK・送料は相談" : "郵送OK"
        }
        return "交換手段は相談"
    }

    // MARK: - 支払行（定価絡みの時のみ表示）

    static func paymentText(for signals: HomeCandidateConditionSignals) -> String? {
        guard case .cash = demandLine(for: signals) else {
            return nil
        }
        let methods = signals.payment.partnerMethods
        guard !methods.isEmpty else {
            return "支払方法は要相談"
        }
        return methods.map(\.displayName).joined(separator: "・") + "OK"
    }

    // MARK: - 並び順（激求含む塊 > 求 > 定価 > 合致なし）

    /// 塊のソートキー：①塊内最大需要ランク（降順）→②需要（求以上）グッズ数（降順）。
    static func sortKey(for candidate: HomeDiscoveryCandidate) -> (Int, Int) {
        let ranks = goodsDemandRanks(of: candidate)
        let bestRank = ranks.max() ?? 0
        let demandCount = ranks.filter { $0 >= 3 }.count
        return (bestRank, demandCount)
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

    /// 塊内のグッズを需要ランク降順（同点は従来順）に並べ替える。先頭が代表グッズ。
    static func orderedGoodsByDemand(of candidate: HomeDiscoveryCandidate) -> [HomeMockGoods] {
        candidate.goods
            .enumerated()
            .sorted { lhs, rhs in
                let lhsRank = demandRank(for: candidate.conditionSignals(for: lhs.element))
                let rhsRank = demandRank(for: candidate.conditionSignals(for: rhs.element))
                if lhsRank == rhsRank {
                    return lhs.offset < rhs.offset
                }
                return lhsRank > rhsRank
            }
            .map(\.element)
    }

    // MARK: - Helpers

    private static func goodsDemandRanks(of candidate: HomeDiscoveryCandidate) -> [Int] {
        guard !candidate.goods.isEmpty else {
            return [demandRank(for: candidate.signals)]
        }
        return candidate.goods.map { goods in
            demandRank(for: candidate.conditionSignals(for: goods))
        }
    }

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

    private static func orderedUnique(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }
}
