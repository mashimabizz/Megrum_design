enum HomeMutualMatchCashCompatibility: Equatable {
    case matched
    case amountIncluded
    case amountInsufficient

    var attentionKind: HomeMutualMatchAttentionKind? {
        switch self {
        case .matched:
            return nil
        case .amountIncluded:
            return .amountIncluded
        case .amountInsufficient:
            return .amountInsufficient
        }
    }
}

enum HomeMutualMatchCashCompatibilityPolicy {
    static func compatibility(
        requestedAmount: Int?,
        counterpartAmount: Int?
    ) -> HomeMutualMatchCashCompatibility {
        switch (requestedAmount, counterpartAmount) {
        case (nil, nil):
            return .matched
        case (nil, _?), (_?, nil):
            return .amountIncluded
        case let (requested?, counterpart?):
            return counterpart >= requested ? .matched : .amountInsufficient
        }
    }
}
