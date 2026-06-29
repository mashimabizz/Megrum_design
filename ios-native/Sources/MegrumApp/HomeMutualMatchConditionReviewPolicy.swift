import Foundation
import MegrumCore

enum HomeMutualMatchConditionReviewPolicy {
    static func review(for pair: HomeMutualMatchProposalPair) -> HomeMutualMatchConditionReview {
        HomeMutualMatchConditionReview(
            exchangeItems: HomeMutualMatchExchangeReviewPolicy.items(for: pair.signals.exchange),
            paymentItems: HomeMutualMatchPaymentReviewPolicy.items(for: pair.signals)
        )
    }
}
