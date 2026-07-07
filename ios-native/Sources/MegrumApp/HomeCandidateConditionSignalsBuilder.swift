import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateConditionSignalsBuilder {
    static func signals(
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
        wishTentativeOfferGoodsIDs: [UUID] = [],
        wishMatchedPartnerUserIDs: [UUID],
        ownerHasMegrumPlus: Bool,
        partnerLookingForText: String? = nil
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
                partnerLocalDateKeys: partnerLocalDateKeys,
                matchedVenue: HomeCandidateExchangePolicy.matchedVenue(
                    viewerWindows: viewerActivityWindows,
                    partnerWindows: partnerActivityWindows
                ),
                matchedLocalDateKeys: HomeCandidateExchangePolicy.matchedLocalDateKeys(
                    viewerWindows: viewerActivityWindows,
                    partnerWindows: partnerActivityWindows
                )
            ),
            payment: paymentSignals,
            linkCounts: linkCounts,
            individualListingSelection: individualListingSelection,
            wishMatchedOfferGoodsIDs: wishMatchedOfferGoodsIDs,
            wishTentativeOfferGoodsIDs: wishTentativeOfferGoodsIDs,
            wishMatchedPartnerUserIDs: wishMatchedPartnerUserIDs,
            matchesViewerWish: matchesViewerWish,
            matchesViewerWishCharacter: matchesViewerWishCharacter,
            tagMatchCount: tagMatchCount,
            ownerHasMegrumPlus: ownerHasMegrumPlus,
            partnerLookingForText: partnerLookingForText
        )
    }
}
