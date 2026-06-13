import Foundation
import MegrumCore

public struct HomeGoodsConditionSignals: Equatable, Sendable {
    public var hasIndividualListingHit: Bool
    public var hasWishHit: Bool

    public init(hasIndividualListingHit: Bool, hasWishHit: Bool) {
        self.hasIndividualListingHit = hasIndividualListingHit
        self.hasWishHit = hasWishHit
    }
}

public struct HomeExchangeConditionSignals: Equatable, Sendable {
    public var postalAcceptedByBoth: Bool
    public var localExchangeSelected: Bool
    public var prefectureMatches: Bool
    public var dateMatches: Bool

    public init(
        postalAcceptedByBoth: Bool,
        localExchangeSelected: Bool,
        prefectureMatches: Bool,
        dateMatches: Bool
    ) {
        self.postalAcceptedByBoth = postalAcceptedByBoth
        self.localExchangeSelected = localExchangeSelected
        self.prefectureMatches = prefectureMatches
        self.dateMatches = dateMatches
    }
}

public struct HomeCandidateLinkCounts: Equatable, Sendable {
    public var wishCount: Int
    public var listingCount: Int

    public init(wishCount: Int = 0, listingCount: Int = 0) {
        self.wishCount = max(0, wishCount)
        self.listingCount = max(0, listingCount)
    }

    public var totalCount: Int {
        wishCount + listingCount
    }

    public static var zero: HomeCandidateLinkCounts {
        HomeCandidateLinkCounts()
    }
}

public struct HomeCandidateConditionSignals: Equatable, Sendable {
    public var goods: HomeGoodsConditionSignals
    public var exchange: HomeExchangeConditionSignals
    public var linkCounts: HomeCandidateLinkCounts

    public init(
        goods: HomeGoodsConditionSignals,
        exchange: HomeExchangeConditionSignals,
        linkCounts: HomeCandidateLinkCounts = .zero
    ) {
        self.goods = goods
        self.exchange = exchange
        self.linkCounts = linkCounts
    }
}

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
        if signals.localExchangeSelected && signals.prefectureMatches && signals.dateMatches {
            return .exact
        }
        if signals.localExchangeSelected && signals.prefectureMatches {
            return .possible
        }
        return .warning
    }
}

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
            linkCounts: HomeCandidateLinkCounts(
                wishCount: max(1, 6 - index),
                listingCount: index.isMultiple(of: 2) ? 2 : 1
            )
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
            linkCounts: HomeCandidateLinkCounts(
                wishCount: max(1, 4 - index),
                listingCount: index.isMultiple(of: 2) ? 1 : 0
            )
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
