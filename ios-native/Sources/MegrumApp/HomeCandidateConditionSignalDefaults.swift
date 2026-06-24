import Foundation
import MegrumCore

enum HomeCandidateConditionSignalDefaults {
    static func previewSignals(
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem]
    ) -> [UUID: HomeCandidateConditionSignals] {
        var result: [UUID: HomeCandidateConditionSignals] = [:]
        for (index, item) in matchedItems.enumerated() {
            result[item.id] = matched(index: index)
        }
        for (index, item) in possibleItems.enumerated() where result[item.id] == nil {
            result[item.id] = possible(index: index)
        }
        return result
    }

    static func matched(index: Int) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: index.isMultiple(of: 2),
                hasWishHit: true
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: index.isMultiple(of: 4),
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: index.isMultiple(of: 3)
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: index.isMultiple(of: 2)),
            linkCounts: HomeCandidateLinkCounts(
                wishCount: max(1, 6 - index),
                listingCount: index.isMultiple(of: 2) ? 2 : 1
            ),
            matchesViewerWish: true,
            tagMatchCount: max(1, 3 - index)
        )
    }

    static func possible(index: Int) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: false,
                hasWishHit: !index.isMultiple(of: 3)
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: !index.isMultiple(of: 2),
                dateMatches: false
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: !index.isMultiple(of: 2)),
            linkCounts: HomeCandidateLinkCounts(
                wishCount: max(1, 4 - index),
                listingCount: index.isMultiple(of: 2) ? 1 : 0
            ),
            matchesViewerWish: !index.isMultiple(of: 3),
            tagMatchCount: index.isMultiple(of: 2) ? 1 : 0
        )
    }

    static var noEvidence: HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: false,
                hasWishHit: false
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: false,
                prefectureMatches: false,
                dateMatches: false
            )
        )
    }
}
