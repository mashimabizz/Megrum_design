import Foundation
import MegrumCore
import MegrumData

enum HomeMutualMatchCandidateSignals {
    static func make(
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

    static func attentionKinds(
        receiveSide: HomeCandidateComposer.MutualListingSideEvaluation,
        giveSide: HomeCandidateComposer.MutualListingSideEvaluation,
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

    static func attentionScore(_ kinds: [HomeMutualMatchAttentionKind]) -> Int {
        kinds.reduce(0) { score, kind in
            score + attentionWeight(kind)
        }
    }

    private static func attentionWeight(_ kind: HomeMutualMatchAttentionKind) -> Int {
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
}
