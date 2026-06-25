enum HomeMutualMatchExchangeRoute: Int {
    case local
    case mail
}

struct HomeMutualMatchExchangeRouteEvaluation {
    var route: HomeMutualMatchExchangeRoute
    var signals: HomeExchangeConditionSignals
    var attentionKinds: [HomeMutualMatchAttentionKind]

    var score: Int {
        attentionKinds.reduce(0) { result, kind in
            result + kind.homeMutualExchangeIssueWeight
        }
    }
}

private extension HomeMutualMatchAttentionKind {
    var homeMutualExchangeIssueWeight: Int {
        switch self {
        case .shippingFeeNeedsDiscussion:
            return 1
        case .dateNeedsDiscussion:
            return 2
        case .prefectureNeedsDiscussion, .prefectureUnset:
            return 3
        case .exchangeMethodMismatch:
            return 100
        case .ready, .tagMismatch, .amountIncluded, .amountInsufficient,
             .paymentMethodMismatch, .viewerPaymentUnset, .partnerPaymentUnset,
             .paymentUnset, .paymentMethodNeedsDiscussion:
            return 0
        }
    }
}
