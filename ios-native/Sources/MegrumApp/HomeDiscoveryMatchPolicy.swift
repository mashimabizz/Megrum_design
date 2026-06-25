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
        guard signals.localExchangeSelected else {
            if signals.postalAcceptedByBoth {
                return signals.shippingFeeNeedsDiscussion ? .possible : .exact
            }
            return .warning
        }
        if signals.prefectureMatches
            && signals.dateMatches
            && !signals.prefectureUnset
            && !signals.dateNeedsDiscussion
            && !signals.shippingFeeNeedsDiscussion {
            return .exact
        }
        if signals.prefectureMatches || signals.dateMatches || signals.prefectureUnset || signals.dateNeedsDiscussion || signals.shippingFeeNeedsDiscussion {
            return .possible
        }
        return .warning
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
              item.memberID != nil
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
