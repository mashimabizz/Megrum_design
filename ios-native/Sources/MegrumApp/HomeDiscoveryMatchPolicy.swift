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

public struct HomePaymentConditionSignals: Equatable, Sendable {
    public var hasCompatiblePaymentMethod: Bool

    public init(hasCompatiblePaymentMethod: Bool) {
        self.hasCompatiblePaymentMethod = hasCompatiblePaymentMethod
    }

    public static var none: HomePaymentConditionSignals {
        HomePaymentConditionSignals(hasCompatiblePaymentMethod: false)
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

public struct HomeIndividualListingSelectionContext: Equatable, Sendable {
    public var wantedLogic: ListingLogic
    public var offeredLogic: ListingLogic
    public var wantedOptions: [HomeIndividualListingWantedOption]

    public init(
        wantedLogic: ListingLogic = .one,
        offeredLogic: ListingLogic = .all,
        wantedOptions: [HomeIndividualListingWantedOption] = []
    ) {
        self.wantedLogic = wantedLogic
        self.offeredLogic = offeredLogic
        self.wantedOptions = wantedOptions
    }

    public static var defaultSelection: HomeIndividualListingSelectionContext {
        HomeIndividualListingSelectionContext()
    }
}

public struct HomeIndividualListingWantedOption: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case goods
        case condition
        case cash
    }

    public var id: UUID
    public var listingID: UUID
    public var position: Int
    public var title: String
    public var subtitle: String?
    public var logic: ListingLogic
    public var kind: Kind
    public var goodsIDs: [UUID]
    public var matchingGoodsIDs: [UUID]
    public var groupID: UUID?
    public var goodsTypeID: UUID?
    public var cashAmount: Int?

    public init(
        id: UUID,
        listingID: UUID,
        position: Int,
        title: String,
        subtitle: String? = nil,
        logic: ListingLogic = .one,
        kind: Kind,
        goodsIDs: [UUID] = [],
        matchingGoodsIDs: [UUID] = [],
        groupID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        cashAmount: Int? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.logic = logic
        self.kind = kind
        self.goodsIDs = goodsIDs
        self.matchingGoodsIDs = matchingGoodsIDs
        self.groupID = groupID
        self.goodsTypeID = goodsTypeID
        self.cashAmount = cashAmount.map { max(0, $0) }
    }

    public var isCashOffer: Bool {
        kind == .cash
    }
}

public struct HomeCandidateConditionSignals: Equatable, Sendable {
    public var goods: HomeGoodsConditionSignals
    public var exchange: HomeExchangeConditionSignals
    public var payment: HomePaymentConditionSignals
    public var linkCounts: HomeCandidateLinkCounts
    public var individualListingSelection: HomeIndividualListingSelectionContext?
    public var matchesViewerWish: Bool
    public var tagMatchCount: Int

    public init(
        goods: HomeGoodsConditionSignals,
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals = .none,
        linkCounts: HomeCandidateLinkCounts = .zero,
        individualListingSelection: HomeIndividualListingSelectionContext? = nil,
        matchesViewerWish: Bool = false,
        tagMatchCount: Int = 0
    ) {
        self.goods = goods
        self.exchange = exchange
        self.payment = payment
        self.linkCounts = linkCounts
        self.individualListingSelection = individualListingSelection
        self.matchesViewerWish = matchesViewerWish
        self.tagMatchCount = max(0, tagMatchCount)
    }
}

enum HomeListingSelectionPolicy {
    static func initialWantedIndices(itemCount: Int, logic: ListingLogic) -> Set<Int> {
        switch logic {
        case .all:
            return allIndices(itemCount: itemCount)
        case .one:
            return []
        }
    }

    static func wantedIndices(
        afterTapping index: Int,
        current: Set<Int>,
        itemCount: Int,
        logic: ListingLogic
    ) -> Set<Int> {
        guard (0..<itemCount).contains(index) else {
            return normalized(current, itemCount: itemCount)
        }

        switch logic {
        case .all:
            return allIndices(itemCount: itemCount)
        case .one:
            return current.contains(index) ? [] : [index]
        }
    }

    static func offerIndices(
        afterTapping index: Int,
        current: Set<Int>,
        itemCount: Int,
        logic: ListingLogic
    ) -> Set<Int> {
        guard (0..<itemCount).contains(index) else {
            return normalized(current, itemCount: itemCount)
        }

        switch logic {
        case .all:
            var updated = normalized(current, itemCount: itemCount)
            if updated.contains(index) {
                updated.remove(index)
            } else {
                updated.insert(index)
            }
            return updated
        case .one:
            return current.contains(index) ? [] : [index]
        }
    }

    static func label(for logic: ListingLogic) -> String {
        switch logic {
        case .all:
            return "すべて希望"
        case .one:
            return "どれか1つだけ"
        }
    }

    private static func allIndices(itemCount: Int) -> Set<Int> {
        guard itemCount > 0 else {
            return []
        }
        return Set(0..<itemCount)
    }

    private static func normalized(_ indices: Set<Int>, itemCount: Int) -> Set<Int> {
        guard itemCount > 0 else {
            return []
        }
        return indices.filter { (0..<itemCount).contains($0) }
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
        if signals.localExchangeSelected && signals.prefectureMatches {
            return .exact
        }
        if signals.localExchangeSelected {
            return .possible
        }
        return .warning
    }

    static func paymentCondition(for signals: HomePaymentConditionSignals) -> HomePaymentCondition {
        signals.hasCompatiblePaymentMethod ? .compatible : .warning
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
