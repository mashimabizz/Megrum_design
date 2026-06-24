import Foundation

struct HomeDiscoveryCandidate: Identifiable, Sendable {
    var id: UUID
    var title: String
    var signals: HomeCandidateConditionSignals
    var conditionSignalsByGoodsID: [UUID: HomeCandidateConditionSignals] = [:]
    var sheet: HomeDiscoverySheet
    var goods: [HomeMockGoods]

    var goodsCondition: HomeGoodsCondition {
        HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods)
    }

    var exchangeCondition: HomeExchangeCondition {
        HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange)
    }

    var paymentCondition: HomePaymentCondition {
        HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment)
    }

    var linkedCount: Int {
        if case .havesLookup(let payload) = sheet {
            return payload.displayCandidateCount
        }
        return signals.linkCounts.totalCount
    }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    func conditionSignals(for goods: HomeMockGoods?) -> HomeCandidateConditionSignals {
        guard let goods else {
            return signals
        }
        return conditionSignalsByGoodsID[goods.id] ?? signals
    }

    func conditionTags(for goods: HomeMockGoods?) -> HomeConditionTagSet {
        HomeConditionTagSet(signals: conditionSignals(for: goods))
    }

    func sheet(selectedGoods: HomeMockGoods? = nil) -> HomeDiscoverySheet {
        let goods = selectedGoods ?? goods.first
        let selectedSignals = conditionSignals(for: goods)
        let payload = HomeDiscoverySheetPayload(
            goods: goods ?? HomeDiscoveryFixtures.selectedYellow,
            signals: selectedSignals,
            preferredOfferGoodsID: preferredOfferGoodsID(from: sheet)
        )
        switch sheet {
        case .goodsHit, .wishHit:
            return HomeDiscoveryMatchPolicy.goodsCondition(for: selectedSignals.goods) == .direct
                ? .goodsHit(payload)
                : .wishHit(payload)
        case .havesLookup(_):
            return sheet
        case .extraListingHit, .extraWishHit:
            return sheet
        }
    }

    private func preferredOfferGoodsID(from sheet: HomeDiscoverySheet) -> UUID? {
        switch sheet {
        case .goodsHit(let payload), .wishHit(let payload):
            return payload.preferredOfferGoodsID
        case .havesLookup(let payload):
            return payload.offeredGoods.id
        case .extraListingHit, .extraWishHit:
            return nil
        }
    }
}

enum HomeDiscoveryCandidateSource: Sendable {
    case userTag
    case user
    case haves
}

enum HomeDiscoverySearchRoutePolicy {
    static func criteria(
        for candidate: HomeDiscoveryCandidate,
        selectedGoods: HomeMockGoods?,
        source: HomeDiscoveryCandidateSource
    ) -> SearchInitialCriteria {
        let goods = selectedGoods ?? candidate.goods.first
        let tagNames: [String]
        switch source {
        case .userTag:
            tagNames = Array((goods?.rawTagNames ?? []).prefix(1))
        case .user, .haves:
            tagNames = []
        }

        let hasMasterCriteria = goods?.groupID != nil || goods?.memberID != nil || goods?.goodsTypeID != nil || !tagNames.isEmpty
        return SearchInitialCriteria(
            query: hasMasterCriteria ? "" : candidate.title,
            groupID: goods?.groupID,
            memberID: goods?.memberID,
            goodsTypeID: source == .haves ? goods?.goodsTypeID : nil,
            tagNames: tagNames
        )
    }
}
