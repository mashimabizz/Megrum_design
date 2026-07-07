import Foundation

/// ホーム候補行v3「需要ファースト」の需要行。優先順位は
/// 激求（指名）＞求（条件一致）＞定価＞探し中＞相談（iter1226.292 で合意した仕様）。
/// 否定文は使わない。
enum HomeCandidateDemandLine: Equatable, Sendable {
    /// 超求！＝相手の個別募集の選択肢（指名・条件）を、無記載なしで確定的に満たせる
    case hotDemand(goodsIDs: [UUID])
    /// 超求めてる？＝個別募集を満たせるが、メンバー/種別/シリーズが無記載で確定できない（iter1226.363）
    case hotDemandTentative(goodsIDs: [UUID])
    /// 求！＝あなたのグッズが相手のほしいものに確定一致
    case demand(goodsIDs: [UUID])
    /// 求めてる？＝ほしいものに当たるが無記載で確定できない（iter1226.363）
    case demandTentative(goodsIDs: [UUID])
    /// 定価交換の選択肢あり
    case cash(amount: Int?)
    /// 合致なしだが相手の探し物が分かる
    case lookingFor(text: String)
    /// 合致なしで相手の求めも不明
    case discuss

    var rank: Int {
        switch self {
        case .hotDemand: 6
        case .hotDemandTentative: 5
        case .demand: 4
        case .demandTentative: 3
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
        let listingOptions = options.filter { $0.kind == .goods || $0.kind == .condition }

        // 超求！＝個別募集の選択肢（指名・条件）を、無記載なしで確定的に満たせる（iter1226.363）。
        let confirmedListingIDs = orderedUnique(
            listingOptions
                .filter { isConfirmedSatisfiable($0) }
                .flatMap { confirmedGoodsIDs(of: $0) }
        )
        if !confirmedListingIDs.isEmpty {
            return .hotDemand(goodsIDs: confirmedListingIDs)
        }

        // 超求めてる？＝個別募集を満たせるが、無記載を含み確定できない。
        let tentativeListingIDs = orderedUnique(
            listingOptions
                .filter { isOfferSatisfiable($0) }
                .flatMap(\.matchingGoodsIDs)
        )
        if !tentativeListingIDs.isEmpty {
            return .hotDemandTentative(goodsIDs: tentativeListingIDs)
        }

        // 求！＝相手のほしいもの（単独リスト）に確定一致。
        let wishTentative = Set(signals.wishTentativeOfferGoodsIDs)
        let wishConfirmedIDs = orderedUnique(
            signals.wishMatchedOfferGoodsIDs.filter { !wishTentative.contains($0) }
        )
        if !wishConfirmedIDs.isEmpty {
            return .demand(goodsIDs: wishConfirmedIDs)
        }

        // 求めてる？＝ほしいものに当たるが無記載で確定できない。
        let wishAllIDs = orderedUnique(signals.wishMatchedOfferGoodsIDs)
        if !wishAllIDs.isEmpty {
            return .demandTentative(goodsIDs: wishAllIDs)
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
        // 確定した需要（求！＝rank4 以上）のグッズ数で副次ソート。
        let demandCount = ranks.filter { $0 >= 4 }.count
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

    /// 相手の選択肢が要求する必要提示数（すべて＝指定グッズ数／n個以上＝n）。
    private static func requiredOfferCount(of option: HomeIndividualListingWantedOption) -> Int {
        HomeListingSelectionPolicy.requiredOfferCount(
            logic: option.logic,
            designatedCount: option.goodsIDs.count,
            minimumCount: option.minimumCount
        )
    }

    /// matchingGoodsIDs のうち、確定（無記載なし）分。iter1226.363。
    private static func confirmedGoodsIDs(of option: HomeIndividualListingWantedOption) -> [UUID] {
        let tentative = Set(option.tentativeGoodsIDs)
        return option.matchingGoodsIDs.filter { !tentative.contains($0) }
    }

    /// 全一致（確定＋不確定）で必要数を満たせるか。満たせない選択肢は需要に数えない（iter1226.361）。
    private static func isOfferSatisfiable(_ option: HomeIndividualListingWantedOption) -> Bool {
        option.matchingGoodsIDs.count >= requiredOfferCount(of: option)
    }

    /// 確定一致だけで必要数を満たせるか（＝超求！／求！の断定条件）。iter1226.363。
    private static func isConfirmedSatisfiable(_ option: HomeIndividualListingWantedOption) -> Bool {
        confirmedGoodsIDs(of: option).count >= requiredOfferCount(of: option)
    }

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
