import Foundation
import MegrumData

enum HomeCandidateViewerOfferSignalsBuilder {
    static func signals(
        viewerItem: SupabaseHomeGoodsRow,
        context: HomeCandidateCompositionContext
    ) -> HomeCandidateConditionSignals {
        let partnerDemand = HomeCandidateViewerOfferDemandSummary(viewerItem: viewerItem, context: context)
        let paymentSignals = HomeCandidatePaymentPolicy.signals(
            viewerMethods: context.viewerUser?.paymentMethods,
            partnerMethodsList: partnerDemand.orderedPartnerIDs.map { context.partnerScope.usersByID[$0]?.paymentMethods }
        )

        return HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: partnerDemand.hasListingHit,
                hasWishHit: partnerDemand.hasWishHit
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: HomeCandidateExchangePolicy.allowsMail(viewerItem.exchangeType) && partnerDemand.partnerAllowsMail,
                localExchangeSelected: HomeCandidateExchangePolicy.allowsLocal(viewerItem.exchangeType) && partnerDemand.partnerAllowsLocal,
                prefectureMatches: partnerDemand.prefectureMatches,
                dateMatches: false,
                partnerExchangeMethodTitle: partnerDemand.partnerExchangeMethodTitle,
                partnerLocalConditionText: partnerDemand.partnerAllowsLocal ? partnerDemand.partnerLocalConditionText : nil,
                partnerLocalPrefectures: partnerDemand.partnerLocalPrefectures,
                partnerLocalDateKeys: partnerDemand.partnerLocalDateKeys
            ),
            payment: paymentSignals,
            linkCounts: partnerDemand.linkCounts,
            individualListingSelection: partnerDemand.individualListingSelection,
            wishMatchedOfferGoodsIDs: partnerDemand.wishMatchedOfferGoodsIDs,
            wishTentativeOfferGoodsIDs: partnerDemand.wishTentativeOfferGoodsIDs,
            wishMatchedPartnerUserIDs: partnerDemand.wishMatchedPartnerUserIDs,
            tagMatchCount: partnerDemand.tagMatchCount
        )
    }
}
