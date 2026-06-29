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
        wishMatchedPartnerUserIDs: [UUID],
        ownerHasMegrumPlus: Bool
    ) -> HomeCandidateConditionSignals {
        let candidateAllowsMail = HomeCandidateExchangePolicy.allowsMail(candidate.exchangeType)
        let candidateAllowsLocal = HomeCandidateExchangePolicy.allowsLocal(candidate.exchangeType)
        let hasDateOverlap = HomeCandidateExchangePolicy.activityWindowsOverlap(viewerActivityWindows, partnerActivityWindows)
        let hasLocalPlaceHint = HomeCandidateExchangePolicy.prefecturesMatch(viewerUser?.primaryArea, partnerUser?.primaryArea)
        let partnerLocalPrefectures = Set([partnerUser?.primaryArea].compactMap(HomeCandidateExchangePolicy.normalizedArea))
        let partnerLocalDateKeys = HomeCandidateExchangePolicy.localDateKeys(from: partnerActivityWindows)
        let partnerExchangeMethodTitle = HomeCandidateExchangePolicy.methodTitle(from: candidate.exchangeType)
            ?? HomeCandidateExchangePolicy.methodTitle(allowsLocal: candidateAllowsLocal, allowsMail: candidateAllowsMail)
        let partnerLocalConditionText = HomeCandidateExchangePolicy.localConditionText(
            prefectures: [partnerUser?.primaryArea].compactMap(\.self),
            dateKeys: partnerLocalDateKeys
        )
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
                dateMatches: hasDateOverlap,
                partnerExchangeMethodTitle: partnerExchangeMethodTitle,
                partnerLocalConditionText: candidateAllowsLocal ? partnerLocalConditionText : nil,
                partnerLocalPrefectures: partnerLocalPrefectures,
                partnerLocalDateKeys: partnerLocalDateKeys
            ),
            payment: paymentSignals,
            linkCounts: linkCounts,
            individualListingSelection: individualListingSelection,
            wishMatchedOfferGoodsIDs: wishMatchedOfferGoodsIDs,
            wishMatchedPartnerUserIDs: wishMatchedPartnerUserIDs,
            matchesViewerWish: matchesViewerWish,
            matchesViewerWishCharacter: matchesViewerWishCharacter,
            tagMatchCount: tagMatchCount,
            ownerHasMegrumPlus: ownerHasMegrumPlus
        )
    }

    static func orderedUnique(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func orderedUnique(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values where seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }

    static func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }

}
