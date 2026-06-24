import Foundation
import MegrumCore
import MegrumData

extension HomeCandidateComposer {
    static func sortedCandidates(_ rows: [SupabaseHomeGoodsRow]) -> [SupabaseHomeGoodsRow] {
        rows.sorted { lhs, rhs in
            switch (lhs.updatedAt, rhs.updatedAt) {
            case let (lhsDate?, rhsDate?):
                lhsDate > rhsDate
            case (_?, nil):
                true
            case (nil, _?):
                false
            case (nil, nil):
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }
    }

    static func conditionSignals(
        candidate: SupabaseHomeGoodsRow,
        partnerUser: SupabaseHomeUserRow?,
        partnerActivityWindows: [SupabaseHomeActivityWindowRow],
        viewerActivityWindows: [SupabaseHomeActivityWindowRow],
        viewerUser: SupabaseHomeUserRow?,
        viewerAllowsMail: Bool,
        viewerAllowsLocal: Bool,
        hasIndividualListingHit: Bool,
        hasWishHit: Bool,
        matchesViewerWish: Bool,
        matchesViewerWishCharacter: Bool,
        tagMatchCount: Int,
        linkCounts: HomeCandidateLinkCounts,
        individualListingSelection: HomeIndividualListingSelectionContext?,
        wishMatchedOfferGoodsIDs: [UUID],
        wishMatchedPartnerUserIDs: [UUID]
    ) -> HomeCandidateConditionSignals {
        let candidateAllowsMail = exchangeAllowsMail(candidate.exchangeType)
        let candidateAllowsLocal = exchangeAllowsLocal(candidate.exchangeType)
        let hasDateOverlap = activityWindowsOverlap(viewerActivityWindows, partnerActivityWindows)
        let hasLocalPlaceHint = prefecturesMatch(viewerUser?.primaryArea, partnerUser?.primaryArea)
        let paymentSignals = HomeCandidatePaymentPolicy.signals(
            viewerMethods: viewerUser?.paymentMethods,
            partnerMethods: partnerUser?.paymentMethods
        )

        return HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: hasIndividualListingHit,
                hasWishHit: hasWishHit
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: candidateAllowsMail && viewerAllowsMail,
                localExchangeSelected: candidateAllowsLocal && viewerAllowsLocal,
                prefectureMatches: hasLocalPlaceHint,
                dateMatches: hasDateOverlap
            ),
            payment: paymentSignals,
            linkCounts: linkCounts,
            individualListingSelection: individualListingSelection,
            wishMatchedOfferGoodsIDs: wishMatchedOfferGoodsIDs,
            wishMatchedPartnerUserIDs: wishMatchedPartnerUserIDs,
            matchesViewerWish: matchesViewerWish,
            matchesViewerWishCharacter: matchesViewerWishCharacter,
            tagMatchCount: tagMatchCount
        )
    }

    static func exchangeAllowsMail(_ value: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: value) else {
            return false
        }
        return method == .mail || method == .both
    }

    static func exchangeAllowsLocal(_ value: String?) -> Bool {
        guard let method = ExchangeMethod(exchangeTypeValue: value) else {
            return true
        }
        return method == .hand || method == .both
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

    static func orderedUnique(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func prefecturesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalizedArea(lhs),
              let rhs = normalizedArea(rhs)
        else {
            return false
        }
        return lhs == rhs
    }

    static func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }

    private static func windowsOverlap(
        _ lhs: SupabaseHomeActivityWindowRow,
        _ rhs: SupabaseHomeActivityWindowRow
    ) -> Bool {
        lhs.startAt < rhs.endAt && rhs.startAt < lhs.endAt
    }

    private static func normalizedArea(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}
