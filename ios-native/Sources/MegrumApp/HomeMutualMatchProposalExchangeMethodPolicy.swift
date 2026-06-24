import MegrumCore

enum HomeMutualMatchProposalExchangeMethodPolicy {
    static func preferredExchangeMethod(for signals: HomeCandidateConditionSignals) -> ExchangeMethod {
        if signals.exchange.localExchangeSelected && signals.exchange.postalAcceptedByBoth {
            return .both
        }
        if signals.exchange.localExchangeSelected {
            return .hand
        }
        if signals.exchange.postalAcceptedByBoth {
            return .mail
        }
        return .hand
    }
}
