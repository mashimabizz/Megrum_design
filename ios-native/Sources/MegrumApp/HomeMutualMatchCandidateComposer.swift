import Foundation
import MegrumCore
import MegrumData

extension HomeCandidateComposer {
    struct MutualListingSideEvaluation {
        var isSatisfied: Bool
        var matchedGoods: [SupabaseHomeGoodsRow]
        var matchedCashOptions: [SupabaseHomeListingWishOptionRow]
        var attentionKinds: [HomeMutualMatchAttentionKind]

        static let unsatisfied = MutualListingSideEvaluation(
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

    struct MutualListingOptionEvaluation {
        var isSatisfied: Bool
        var matchedGoods: [SupabaseHomeGoodsRow]
        var matchedCashOptions: [SupabaseHomeListingWishOptionRow]
        var attentionKinds: [HomeMutualMatchAttentionKind]

        static let unsatisfied = MutualListingOptionEvaluation(
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

    static func mutualMatchCandidates(
        from composition: SupabaseHomeComposition,
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]],
        listingOptionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        partnerUsersByID: [UUID: SupabaseHomeUserRow]
    ) -> [HomeMutualMatchCandidateData] {
        let viewerInventory = composition.viewerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let partnerInventory = composition.partnerInventory.filter(HomeCandidateRowMapper.isMarketAvailable)
        let rowsByID = goodsRowsByID(
            composition.viewerInventory
                + composition.viewerWishes
                + composition.partnerInventory
                + composition.partnerWishes
        )
        var result: [HomeMutualMatchCandidateData] = []
        var seenCandidateIDs: Set<UUID> = []

        for viewerListing in activeListings(composition.viewerListings) {
            let viewerOffers = offeredRows(for: viewerListing, inventory: viewerInventory)
            guard !viewerOffers.isEmpty else {
                continue
            }

            for partnerListing in activeListings(composition.partnerListings) {
                let partnerOffers = offeredRows(for: partnerListing, inventory: partnerInventory)
                guard !partnerOffers.isEmpty else {
                    continue
                }

                let viewerOptions = sortedOptions(listingOptionsByListingID[viewerListing.id, default: []])
                let partnerOptions = sortedOptions(listingOptionsByListingID[partnerListing.id, default: []])
                let receiveSide = evaluateWantedSide(
                    options: viewerOptions,
                    counterpartOffers: partnerOffers,
                    counterpartCashOptions: partnerOptions,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
                guard receiveSide.isSatisfied else {
                    continue
                }

                let giveSide = evaluateWantedSide(
                    options: partnerOptions,
                    counterpartOffers: viewerOffers,
                    counterpartCashOptions: viewerOptions,
                    rowsByID: rowsByID,
                    tagsByInventoryID: tagsByInventoryID
                )
                guard giveSide.isSatisfied else {
                    continue
                }

                let partnerGoods = receiveSide.matchedGoods.isEmpty ? partnerOffers : receiveSide.matchedGoods
                let viewerGoods = giveSide.matchedGoods.isEmpty ? viewerOffers : giveSide.matchedGoods
                guard let firstPartnerGoods = partnerGoods.first else {
                    continue
                }

                let partnerUser = partnerUsersByID[partnerListing.userId]
                let exchangeEvaluation = HomeMutualMatchConditionPolicy.exchangeEvaluation(
                    viewerListing: viewerListing,
                    viewerUser: composition.viewerUser,
                    partnerListing: partnerListing,
                    partnerUser: partnerUser
                )
                let requiresPayment = !receiveSide.matchedCashOptions.isEmpty
                    || !giveSide.matchedCashOptions.isEmpty
                let paymentEvaluation = HomeMutualMatchConditionPolicy.paymentEvaluation(
                    viewerMethods: composition.viewerUser?.paymentMethods ?? [],
                    partnerMethods: partnerUser?.paymentMethods ?? [],
                    requiresPayment: requiresPayment
                )
                let attentionKinds = mutualAttentionKinds(
                    receiveSide: receiveSide,
                    giveSide: giveSide,
                    exchangeKinds: exchangeEvaluation.attentionKinds,
                    paymentKinds: paymentEvaluation.attentionKinds
                )
                let signals = mutualConditionSignals(
                    partnerListing: partnerListing,
                    partnerOptions: partnerOptions,
                    viewerOffers: viewerOffers,
                    exchange: exchangeEvaluation.signals,
                    payment: paymentEvaluation.signals,
                    tagMatchCount: HomeCandidateTagMatcher.count(
                        itemID: firstPartnerGoods.id,
                        matchingRows: viewerGoods,
                        tagsByInventoryID: tagsByInventoryID
                    )
                )
                let partnerGoodsItems = Array(
                    deduplicatedRows(partnerGoods).prefix(4)
                ).map { row in
                    HomeCandidateRowMapper.makeGoodsItem(
                        from: row,
                        tags: tagsByInventoryID[row.id] ?? [],
                        ownerPrefecture: partnerUser?.primaryArea,
                        ownerPaymentMethods: partnerUser?.paymentMethods ?? [],
                        ownerPaymentNote: partnerUser?.paymentNote
                    )
                }
                let viewerGoodsItems = Array(
                    deduplicatedRows(viewerGoods).prefix(4)
                ).map { row in
                    HomeCandidateRowMapper.makeGoodsItem(
                        from: row,
                        tags: tagsByInventoryID[row.id] ?? [],
                        ownerPrefecture: composition.viewerUser?.primaryArea,
                        ownerPaymentMethods: composition.viewerUser?.paymentMethods ?? [],
                        ownerPaymentNote: composition.viewerUser?.paymentNote
                    )
                }
                let partnerDisplayItems = displayItems(
                    goodsItems: partnerGoodsItems,
                    cashOptions: receiveSide.matchedCashOptions
                )
                let viewerDisplayItems = displayItems(
                    goodsItems: viewerGoodsItems,
                    cashOptions: giveSide.matchedCashOptions
                )
                let candidateID = stableMutualCandidateID(
                    viewerListingID: viewerListing.id,
                    partnerListingID: partnerListing.id
                )
                guard seenCandidateIDs.insert(candidateID).inserted else {
                    continue
                }

                result.append(
                    HomeMutualMatchCandidateData(
                        id: candidateID,
                        partnerID: partnerListing.userId,
                        partnerName: displayName(for: partnerUser, fallbackID: partnerListing.userId),
                        partnerHandle: handle(for: partnerUser, fallbackID: partnerListing.userId),
                        partnerInitial: initial(for: partnerUser, fallbackID: partnerListing.userId),
                        partnerArea: partnerUser?.primaryArea ?? "地域未設定",
                        partnerOshiText: oshiText(for: firstPartnerGoods),
                        partnerAgeRangeText: ageRangeText(for: partnerUser?.age),
                        partnerEvaluationSummaryText: evaluationSummaryText(for: partnerUser),
                        partnerGoodsItems: partnerGoodsItems,
                        viewerGoodsItems: viewerGoodsItems,
                        partnerDisplayItems: partnerDisplayItems,
                        viewerDisplayItems: viewerDisplayItems,
                        signals: signals,
                        conditionSignalsByPartnerGoodsID: Dictionary(
                            uniqueKeysWithValues: partnerGoodsItems.map { ($0.id, signals) }
                        ),
                        attentionKinds: attentionKinds
                    )
                )
            }
        }

        return result
            .sorted { lhs, rhs in
                let lhsScore = mutualAttentionScore(lhs.attentionKinds)
                let rhsScore = mutualAttentionScore(rhs.attentionKinds)
                if lhsScore == rhsScore {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhsScore < rhsScore
            }
            .prefix(12)
            .map { $0 }
    }

    private static func evaluateWantedSide(
        options: [SupabaseHomeListingWishOptionRow],
        counterpartOffers: [SupabaseHomeGoodsRow],
        counterpartCashOptions: [SupabaseHomeListingWishOptionRow],
        rowsByID: [UUID: SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]]
    ) -> MutualListingSideEvaluation {
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
            return MutualListingSideEvaluation(
                isSatisfied: true,
                matchedGoods: best.matchedGoods,
                matchedCashOptions: best.matchedCashOptions,
                attentionKinds: best.attentionKinds
            )
        case .all:
            guard optionResults.allSatisfy(\.isSatisfied) else {
                return .unsatisfied
            }
            return MutualListingSideEvaluation(
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
    ) -> MutualListingOptionEvaluation {
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
                rowsByID: rowsByID
            )
        }
        guard !matchedGoods.isEmpty else {
            return .unsatisfied
        }
        if ListingLogic(rawValue: option.logic ?? "") == .atLeast,
           matchedGoods.count < max(1, option.minCount ?? 1) {
            return .unsatisfied
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

        return MutualListingOptionEvaluation(
            isSatisfied: true,
            matchedGoods: matchedGoods,
            matchedCashOptions: [],
            attentionKinds: hasTagMismatch ? [.tagMismatch] : []
        )
    }

    private static func evaluateCashWantedOption(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartCashOptions: [SupabaseHomeListingWishOptionRow]
    ) -> MutualListingOptionEvaluation {
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

        return MutualListingOptionEvaluation(
            isSatisfied: true,
            matchedGoods: [],
            matchedCashOptions: [option],
            attentionKinds: best.attentionKind.map { [$0] } ?? []
        )
    }

    private static func displayItems(
        goodsItems: [GoodsItem],
        cashOptions: [SupabaseHomeListingWishOptionRow]
    ) -> [HomeMutualMatchDisplayItemData] {
        let cashItems = cashOptions.map { option in
            HomeMutualMatchDisplayItemData.cash(id: option.id, amount: option.cashAmount)
        }
        guard !cashItems.isEmpty else {
            return goodsItems.map(HomeMutualMatchDisplayItemData.goods)
        }
        return cashItems
    }

    private static func activeListings(_ listings: [SupabaseHomeListingRow]) -> [SupabaseHomeListingRow] {
        listings.filter { listing in
            guard let status = listing.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !status.isEmpty
            else {
                return true
            }
            return status == IndividualListingStatus.active.rawValue
        }
    }

    private static func offeredRows(
        for listing: SupabaseHomeListingRow,
        inventory: [SupabaseHomeGoodsRow]
    ) -> [SupabaseHomeGoodsRow] {
        if !listing.haveIds.isEmpty {
            return inventory.filter { listing.haveIds.contains($0.id) }
        }
        guard listing.haveGroupId != nil || listing.haveGoodsTypeId != nil else {
            return []
        }
        return inventory.filter { row in
            HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, row.groupId)
                && HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, row.goodsTypeId)
        }
    }

    private static func sortedOptions(
        _ options: [SupabaseHomeListingWishOptionRow]
    ) -> [SupabaseHomeListingWishOptionRow] {
        options.sorted { lhs, rhs in
            if lhs.position == rhs.position {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.position < rhs.position
        }
    }

    private static func goodsRowsByID(_ rows: [SupabaseHomeGoodsRow]) -> [UUID: SupabaseHomeGoodsRow] {
        rows.reduce(into: [UUID: SupabaseHomeGoodsRow]()) { result, row in
            result[row.id] = result[row.id] ?? row
        }
    }

    private static func mutualConditionSignals(
        partnerListing: SupabaseHomeListingRow,
        partnerOptions: [SupabaseHomeListingWishOptionRow],
        viewerOffers: [SupabaseHomeGoodsRow],
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals,
        tagMatchCount: Int
    ) -> HomeCandidateConditionSignals {
        let wantedOptions = partnerOptions.compactMap { option in
            HomeCandidateListingMatchPolicy.wantedOption(
                from: option,
                viewerInventory: viewerOffers,
                includesCash: true
            )
        }
        let selection = wantedOptions.isEmpty ? nil : HomeIndividualListingSelectionContext(
            wantedLogic: ListingLogic(rawValue: partnerOptions.first?.logic ?? "") ?? .one,
            offeredLogic: ListingLogic(rawValue: partnerListing.haveLogic ?? "") ?? .all,
            wantedOptions: wantedOptions
        )
        return HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: true,
                hasWishHit: false
            ),
            exchange: exchange,
            payment: payment,
            linkCounts: HomeCandidateLinkCounts(
                wishCount: 0,
                listingCount: 1
            ),
            individualListingSelection: selection,
            matchesViewerWish: true,
            tagMatchCount: tagMatchCount
        )
    }

    private static func mutualAttentionKinds(
        receiveSide: MutualListingSideEvaluation,
        giveSide: MutualListingSideEvaluation,
        exchangeKinds: [HomeMutualMatchAttentionKind],
        paymentKinds: [HomeMutualMatchAttentionKind]
    ) -> [HomeMutualMatchAttentionKind] {
        let allKinds = receiveSide.attentionKinds + giveSide.attentionKinds + exchangeKinds + paymentKinds
        let orderedKinds: [HomeMutualMatchAttentionKind] = [
            .amountInsufficient,
            .amountIncluded,
            .exchangeMethodMismatch,
            .paymentMethodMismatch,
            .paymentUnset,
            .viewerPaymentUnset,
            .partnerPaymentUnset,
            .paymentMethodNeedsDiscussion,
            .prefectureUnset,
            .prefectureNeedsDiscussion,
            .dateNeedsDiscussion,
            .shippingFeeNeedsDiscussion,
            .tagMismatch
        ]
        let result = orderedKinds.filter { allKinds.contains($0) }
        return result.isEmpty ? [.ready] : result
    }

    private static func mutualAttentionScore(_ kinds: [HomeMutualMatchAttentionKind]) -> Int {
        kinds.reduce(0) { score, kind in
            score + mutualAttentionWeight(kind)
        }
    }

    private static func mutualAttentionWeight(_ kind: HomeMutualMatchAttentionKind) -> Int {
        switch kind {
        case .ready:
            return 0
        case .tagMismatch, .shippingFeeNeedsDiscussion:
            return 1
        case .amountIncluded, .dateNeedsDiscussion, .paymentMethodNeedsDiscussion:
            return 2
        case .amountInsufficient, .prefectureNeedsDiscussion, .prefectureUnset,
             .viewerPaymentUnset, .partnerPaymentUnset, .paymentUnset:
            return 3
        case .paymentMethodMismatch:
            return 4
        case .exchangeMethodMismatch:
            return 5
        }
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

    private static func stableMutualCandidateID(
        viewerListingID: UUID,
        partnerListingID: UUID
    ) -> UUID {
        let seed = "\(viewerListingID.uuidString)-\(partnerListingID.uuidString)"
        let hash = seed.utf8.reduce(UInt64(5381)) { partial, byte in
            ((partial << 5) &+ partial) &+ UInt64(byte)
        }
        let tail = String(format: "%012llu", hash % 1_000_000_000_000)
        return UUID(uuidString: "00000000-0000-0000-0000-\(tail)")
            ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }

    private static func displayName(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        trimmed(user?.displayName) ?? trimmed(user?.handle) ?? "相手\(fallbackID.uuidString.prefix(2))"
    }

    private static func handle(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        trimmed(user?.handle) ?? "user_\(fallbackID.uuidString.prefix(4).lowercased())"
    }

    private static func initial(for user: SupabaseHomeUserRow?, fallbackID: UUID) -> String {
        let source = trimmed(user?.displayName) ?? trimmed(user?.handle)
        return source?.first.map { String($0).uppercased() }
            ?? String(fallbackID.uuidString.prefix(1)).uppercased()
    }

    private static func ageRangeText(for age: Int?) -> String? {
        guard let age, age > 0 else {
            return nil
        }
        if age < 10 {
            return "10代未満"
        }
        let decade = min(age / 10 * 10, 100)
        return "\(decade)代"
    }

    private static func evaluationSummaryText(for user: SupabaseHomeUserRow?) -> String? {
        guard let count = user?.evaluationCount else {
            return nil
        }
        if let average = user?.averageStars, count > 0 {
            return "評価\(count)件 ★\(String(format: "%.1f", average))"
        }
        return "評価\(count)件 ★—"
    }

    private static func oshiText(for row: SupabaseHomeGoodsRow) -> String {
        if let characterName = trimmed(row.characterName) {
            return "\(characterName)推し"
        }
        if let groupName = trimmed(row.groupName) {
            return "\(groupName)推し"
        }
        return "推し未設定"
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

    private static func mutualOptionWantsCounterpartGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        counterpartItem: SupabaseHomeGoodsRow,
        rowsByID: [UUID: SupabaseHomeGoodsRow]
    ) -> Bool {
        guard option.isCashOffer != true else {
            return false
        }
        if option.wishIds.contains(counterpartItem.id) {
            return true
        }

        let wantedRows = option.wishIds.compactMap { rowsByID[$0] }
        if !wantedRows.isEmpty {
            return wantedRows.contains { wishRow($0, matches: counterpartItem) }
        }

        guard option.wishGroupId != nil || option.wishGoodsTypeId != nil else {
            return false
        }
        return HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGroupId, counterpartItem.groupId)
            && HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGoodsTypeId, counterpartItem.goodsTypeId)
    }
}
