import MegrumCore

enum HomeDiscoveryMatchPolicy {
    static func goodsCondition(for signals: HomeGoodsConditionSignals) -> HomeGoodsCondition {
        if signals.hasIndividualListingHit {
            return .direct
        }
        if signals.hasWishHit {
            return .wish
        }
        return .none
    }

    static func exchangeCondition(for signals: HomeExchangeConditionSignals) -> HomeExchangeCondition {
        if signals.postalAcceptedByBoth {
            return .exact
        }

        guard signals.localExchangeSelected else {
            return .warning
        }

        if signals.prefectureMatches && signals.dateMatches && !signals.prefectureUnset {
            return .exact
        }

        return .possible
    }

    static func paymentCondition(for signals: HomePaymentConditionSignals) -> HomePaymentCondition {
        switch signals.status {
        case .compatible:
            return .exact
        case .skipped, .needsDiscussion:
            return .compatible
        case .viewerUnset, .partnerUnset, .unset:
            return .unknown
        case .methodMismatch:
            return .warning
        }
    }

    static func isMemberMatchEligible(item: GoodsItem, signals: HomeCandidateConditionSignals?) -> Bool {
        guard let signals,
              signals.matchesViewerWish,
              signals.matchesViewerWishCharacter,
              item.memberID != nil || item.groupID != nil
        else {
            return false
        }
        return true
    }

    static func isMemberTagMatchEligible(item: GoodsItem, signals: HomeCandidateConditionSignals?) -> Bool {
        isMemberMatchEligible(item: item, signals: signals)
            && (signals?.tagMatchCount ?? 0) > 0
    }
}
