import Foundation
import MegrumCore
import MegrumData

struct HomeMutualMatchListingSideEvaluation {
    var isSatisfied: Bool
    var matchedGoods: [SupabaseHomeGoodsRow]
    var matchedCashOptions: [SupabaseHomeListingWishOptionRow]
    var attentionKinds: [HomeMutualMatchAttentionKind]

    static let unsatisfied = HomeMutualMatchListingSideEvaluation(
        isSatisfied: false,
        matchedGoods: [],
        matchedCashOptions: [],
        attentionKinds: []
    )

    var score: Int {
        if attentionKinds.contains(.amountInsufficient) {
            return 3
        }
        if attentionKinds.contains(.amountIncluded) {
            return 2
        }
        if attentionKinds.contains(.tagMismatch) {
            return 1
        }
        return 0
    }
}

struct HomeMutualMatchListingOptionEvaluation {
    var isSatisfied: Bool
    var matchedGoods: [SupabaseHomeGoodsRow]
    var matchedCashOptions: [SupabaseHomeListingWishOptionRow]
    var attentionKinds: [HomeMutualMatchAttentionKind]

    static let unsatisfied = HomeMutualMatchListingOptionEvaluation(
        isSatisfied: false,
        matchedGoods: [],
        matchedCashOptions: [],
        attentionKinds: []
    )

    var score: Int {
        if attentionKinds.contains(.amountInsufficient) {
            return 3
        }
        if attentionKinds.contains(.amountIncluded) {
            return 2
        }
        if attentionKinds.contains(.tagMismatch) {
            return 1
        }
        return 0
    }
}

enum HomeMutualMatchListingEvaluator {
    static func evaluateWantedSide(
        options: [SupabaseHomeListingWishOptionRow],
        counterpartOffers: [SupabaseHomeGoodsRow],
        counterpartCashOptions: [SupabaseHomeListingWishOptionRow],
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> HomeMutualMatchListingSideEvaluation {
        guard !options.isEmpty else {
            return .unsatisfied
        }

        let logic = ListingLogic(rawValue: options.first?.logic ?? "") ?? .one
        let optionResults = options.map { option in
            evaluateWantedOption(
                option,
                counterpartOffers: counterpartOffers,
                counterpartCashOptions: counterpartCashOptions,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            )
        }

        switch logic {
        case .one, .atLeast:
            guard let best = optionResults
                .filter(\.isSatisfied)
                .sorted(by: { $0.score < $1.score })
                .first
            else {
                return .unsatisfied
            }
            return HomeMutualMatchListingSideEvaluation(
                isSatisfied: true,
                matchedGoods: best.matchedGoods,
                matchedCashOptions: best.matchedCashOptions,
                attentionKinds: best.attentionKinds
            )
        case .all:
            guard optionResults.allSatisfy(\.isSatisfied) else {
                return .unsatisfied
            }
            return HomeMutualMatchListingSideEvaluation(
                isSatisfied: true,
                matchedGoods: deduplicatedRows(optionResults.flatMap(\.matchedGoods)),
                matchedCashOptions: optionResults.flatMap(\.matchedCashOptions),
                attentionKinds: deduplicatedAttentionKinds(optionResults.flatMap(\.attentionKinds))
            )
        }
    }

    private static func evaluateWantedOption(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartOffers: [SupabaseHomeGoodsRow],
        counterpartCashOptions: [SupabaseHomeListingWishOptionRow],
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> HomeMutualMatchListingOptionEvaluation {
        if option.isCashOffer == true {
            return evaluateCashWantedOption(
                option,
                counterpartCashOptions: counterpartCashOptions
            )
        }

        let matchedGoods = counterpartOffers.filter { offer in
            mutualOptionWantsCounterpartGoods(
                option,
                counterpartItem: offer,
                rowsByID: rowsByID,
                tagsByInventoryID: tagsByInventoryID
            )
        }
        guard !matchedGoods.isEmpty else {
            return .unsatisfied
        }
        if ListingLogic(rawValue: option.logic ?? "") == .atLeast,
           matchedGoods.count < max(1, option.minCount ?? 1) {
            return .unsatisfied
        }
        // 条件指定型（ほしいもの未指定）の選択肢は、求める数量を満たす
        // 在庫がある相手だけをマッチとする。
        if option.wishIds.isEmpty, option.wishQuantity > 1 {
            let availableQuantity = matchedGoods.reduce(0) { $0 + max(1, $1.quantity ?? 1) }
            if availableQuantity < option.wishQuantity {
                return .unsatisfied
            }
        }

        let wantedRows = option.wishIds.compactMap { rowsByID[$0] }
        let hasTagMismatch = !wantedRows.isEmpty
            && matchedGoods.contains { matched in
                tagsDoNotOverlap(
                    matched,
                    wantedRows: wantedRows,
                    tagsByInventoryID: tagsByInventoryID
                )
            }

        return HomeMutualMatchListingOptionEvaluation(
            isSatisfied: true,
            matchedGoods: matchedGoods,
            matchedCashOptions: [],
            attentionKinds: hasTagMismatch ? [.tagMismatch] : []
        )
    }

    private static func evaluateCashWantedOption(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartCashOptions: [SupabaseHomeListingWishOptionRow]
    ) -> HomeMutualMatchListingOptionEvaluation {
        let compatibleKinds = counterpartCashOptions
            .filter { $0.isCashOffer == true }
            .map {
                HomeMutualMatchCashCompatibilityPolicy.compatibility(
                    requestedAmount: option.cashAmount,
                    counterpartAmount: $0.cashAmount
                )
            }
        guard let best = compatibleKinds.sorted(by: cashCompatibilitySorter).first else {
            return .unsatisfied
        }

        return HomeMutualMatchListingOptionEvaluation(
            isSatisfied: true,
            matchedGoods: [],
            matchedCashOptions: [option],
            attentionKinds: best.attentionKind.map { [$0] } ?? []
        )
    }

    private static func cashCompatibilitySorter(
        lhs: HomeMutualMatchCashCompatibility,
        rhs: HomeMutualMatchCashCompatibility
    ) -> Bool {
        cashCompatibilityScore(lhs) < cashCompatibilityScore(rhs)
    }

    private static func cashCompatibilityScore(_ compatibility: HomeMutualMatchCashCompatibility) -> Int {
        switch compatibility {
        case .matched:
            return 0
        case .amountIncluded:
            return 1
        case .amountInsufficient:
            return 2
        }
    }

    private static func tagsDoNotOverlap(
        _ matched: SupabaseHomeGoodsRow,
        wantedRows: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> Bool {
        let matchedTags = HomeCandidateTagMatcher.normalizedSet(tagsByInventoryID[matched.id] ?? [])
        let wantedTags = wantedRows.reduce(into: Set<String>()) { result, row in
            result.formUnion(HomeCandidateTagMatcher.normalizedSet(tagsByInventoryID[row.id] ?? []))
        }
        guard !matchedTags.isEmpty, !wantedTags.isEmpty else {
            return false
        }
        return matchedTags.isDisjoint(with: wantedTags)
    }

    private static func deduplicatedRows(_ rows: [SupabaseHomeGoodsRow]) -> [SupabaseHomeGoodsRow] {
        var seen: Set<UUID> = []
        var result: [SupabaseHomeGoodsRow] = []
        for row in rows where seen.insert(row.id).inserted {
            result.append(row)
        }
        return result
    }

    private static func deduplicatedAttentionKinds(
        _ kinds: [HomeMutualMatchAttentionKind]
    ) -> [HomeMutualMatchAttentionKind] {
        var seen: Set<HomeMutualMatchAttentionKind> = []
        var result: [HomeMutualMatchAttentionKind] = []
        for kind in kinds where seen.insert(kind).inserted {
            result.append(kind)
        }
        return result
    }

    static func mutualOptionWantsCounterpartGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartItem: SupabaseHomeGoodsRow,
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> Bool {
        mutualOptionMatchConfidence(
            option,
            counterpartItem: counterpartItem,
            rowsByID: rowsByID,
            tagsByInventoryID: tagsByInventoryID
        ) != nil
    }

    /// 相手の選択肢と自分のグッズの一致確度（確定/不確定/非マッチ）。iter1226.363。
    /// メンバー・種別・シリーズは、相手が指定していて自分が無記載なら「不確定」、別値なら非マッチ。
    static func mutualOptionMatchConfidence(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartItem: SupabaseHomeGoodsRow,
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> HomeCandidateMatchConfidence? {
        guard option.isCashOffer != true else {
            return nil
        }
        // 1. 現物IDを直接指名しているケース（確定）。
        if option.wishIds.contains(counterpartItem.id) {
            return .confirmed
        }
        // 2. 指名グッズ（相手のほしいもの行）と軸判定。最良の確度を採用。
        let wantedRows = option.wishIds.compactMap { rowsByID[$0] }
        if !wantedRows.isEmpty {
            var best: HomeCandidateMatchConfidence?
            for wish in wantedRows {
                if let confidence = wishGoodsConfidence(
                    wish: wish,
                    item: counterpartItem,
                    tagsByInventoryID: tagsByInventoryID
                ) {
                    best = HomeCandidateMatchConfidencePolicy.better(best, confidence)
                }
            }
            return best
        }
        // 3. 条件指定（グループ/種別＋メンバー/シリーズ/数量）。
        guard option.wishGroupId != nil || option.wishGoodsTypeId != nil else {
            return nil
        }
        // 数量はハード条件（満たせなければ非マッチ）。
        if option.wishQuantity > 1 {
            let availableQuantity = counterpartItem.marketAvailableQty
                ?? counterpartItem.quantity
                ?? 1
            if availableQuantity < option.wishQuantity {
                return nil
            }
        }
        let series = HomeCandidateMatchConfidencePolicy.seriesAxis(
            wanted: Set(option.wishSeriesNames.compactMap(HomeCandidateTagMatcher.normalizedName)),
            itemTags: HomeCandidateTagMatcher.normalizedSet(tagsByInventoryID[counterpartItem.id] ?? [])
        )
        return HomeCandidateMatchConfidencePolicy.combine([
            HomeCandidateMatchConfidencePolicy.idAxis(expected: option.wishGroupId, actual: counterpartItem.groupId),
            HomeCandidateMatchConfidencePolicy.idAxis(expected: option.wishGoodsTypeId, actual: counterpartItem.goodsTypeId),
            HomeCandidateMatchConfidencePolicy.memberAxis(
                wishMemberIds: option.wishMemberIds,
                excludes: option.excludesWishMembers,
                actual: counterpartItem.characterId
            ),
            series
        ])
    }

    /// 相手のほしいもの1件（指名グッズ）と自分のグッズの軸判定（グループ・メンバー・種別・シリーズ）。
    static func wishGoodsConfidence(
        wish: SupabaseHomeGoodsRow,
        item: SupabaseHomeGoodsRow,
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:]
    ) -> HomeCandidateMatchConfidence? {
        let series = HomeCandidateMatchConfidencePolicy.seriesAxis(
            wanted: HomeCandidateTagMatcher.normalizedSet(tagsByInventoryID[wish.id] ?? []),
            itemTags: HomeCandidateTagMatcher.normalizedSet(tagsByInventoryID[item.id] ?? [])
        )
        return HomeCandidateMatchConfidencePolicy.combine([
            HomeCandidateMatchConfidencePolicy.idAxis(expected: wish.groupId, actual: item.groupId),
            HomeCandidateMatchConfidencePolicy.idAxis(expected: wish.characterId, actual: item.characterId),
            HomeCandidateMatchConfidencePolicy.idAxis(expected: wish.goodsTypeId, actual: item.goodsTypeId),
            series
        ])
    }
}
