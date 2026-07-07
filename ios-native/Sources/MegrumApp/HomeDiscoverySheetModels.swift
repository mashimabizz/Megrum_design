import Foundation

enum HomeDiscoverySheet: Identifiable, Sendable {
    case goodsHit(HomeDiscoverySheetPayload)
    case wishHit(HomeDiscoverySheetPayload)
    case havesLookup(HomeHavesLookupPayload)
    case extraListingHit(HomeExtraHitPayload)
    case extraWishHit(HomeExtraHitPayload)

    var id: String {
        switch self {
        case .goodsHit(let payload):
            "goods-hit-\(payload.id.uuidString)"
        case .wishHit(let payload):
            "wish-hit-\(payload.id.uuidString)"
        case .havesLookup(let payload):
            "haves-lookup-\(payload.id.uuidString)"
        case .extraListingHit(let payload):
            "extra-listing-hit-\(payload.id)"
        case .extraWishHit(let payload):
            "extra-wish-hit-\(payload.id)"
        }
    }

    /// 候補シートの主対象グッズ（相手の在庫）。「他にも交換できそうなもの」を相手軸で組む時に使う。iter1226.383。
    var primaryGoods: HomeMockGoods? {
        switch self {
        case .goodsHit(let payload), .wishHit(let payload):
            return payload.goods
        case .extraListingHit(let payload), .extraWishHit(let payload):
            return payload.goods
        case .havesLookup:
            return nil
        }
    }
}

struct HomeDiscoverySheetPayload: Identifiable, Equatable, Sendable {
    var goods: HomeMockGoods
    var signals: HomeCandidateConditionSignals
    var preferredOfferGoodsID: UUID?

    var id: UUID { goods.id }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    var individualListingSelection: HomeIndividualListingSelectionContext {
        signals.individualListingSelection ?? .defaultSelection
    }

    init(
        goods: HomeMockGoods,
        signals: HomeCandidateConditionSignals = HomeCandidateConditionSignalDefaults.noEvidence,
        preferredOfferGoodsID: UUID? = nil
    ) {
        self.goods = goods
        self.signals = signals
        self.preferredOfferGoodsID = preferredOfferGoodsID
    }
}

struct HomeHavesLookupPayload: Identifiable, Sendable {
    var offeredGoods: HomeMockGoods
    var offeredSignals: HomeCandidateConditionSignals
    var tagMatchedCandidates: [HomeDiscoveryCandidate]
    var memberMatchedCandidates: [HomeDiscoveryCandidate]

    var id: UUID { offeredGoods.id }

    var offeredConditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: offeredSignals)
    }

    var shouldShowTagMatches: Bool {
        !offeredGoods.rawTagNames.isEmpty && !tagMatchedCandidates.isEmpty
    }

    var hasAnyMatches: Bool {
        shouldShowTagMatches || !memberMatchedCandidates.isEmpty
    }

    var displayCandidateCount: Int {
        tagMatchedCandidates.count + memberMatchedCandidates.count
    }
}

enum HomeExtraHitKind: String, Equatable, Sendable {
    case listing
    case wish
}

struct HomeExtraHitPayload: Identifiable, Equatable, Sendable {
    var kind: HomeExtraHitKind
    var goods: HomeMockGoods
    var signals: HomeCandidateConditionSignals

    var id: String {
        "\(kind.rawValue)-\(goods.id.uuidString)"
    }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    var individualListingSelection: HomeIndividualListingSelectionContext {
        signals.individualListingSelection ?? .defaultSelection
    }

    var sheetPayload: HomeDiscoverySheetPayload {
        HomeDiscoverySheetPayload(goods: goods, signals: signals)
    }

    var nestedSheet: HomeDiscoverySheet {
        switch kind {
        case .listing:
            .goodsHit(sheetPayload)
        case .wish:
            .wishHit(sheetPayload)
        }
    }
}
