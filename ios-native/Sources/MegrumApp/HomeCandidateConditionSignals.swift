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
    public var prefectureUnset: Bool
    public var dateNeedsDiscussion: Bool
    public var shippingFeeNeedsDiscussion: Bool
    public var viewerExchangeMethodTitle: String?
    public var partnerExchangeMethodTitle: String?
    public var viewerLocalConditionText: String?
    public var partnerLocalConditionText: String?
    public var viewerShippingFeeTitle: String?
    public var partnerShippingFeeTitle: String?
    public var localRouteAvailable: Bool
    public var localRoutePrefectureMatches: Bool
    public var localRouteDateMatches: Bool
    public var localRoutePrefectureUnset: Bool
    public var localRouteDateNeedsDiscussion: Bool
    public var partnerLocalPrefectures: Set<String>
    public var partnerLocalDateKeys: Set<String>
    /// 自分と相手のAWが重なった時の会場名（結論一文の「〈会場〉で」表示用）。
    public var matchedVenue: String?
    /// 自分と相手の現地日程が重なった日付キー（結論一文の「〈M/D〉に」表示用）。
    public var matchedLocalDateKeys: Set<String>

    public init(
        postalAcceptedByBoth: Bool,
        localExchangeSelected: Bool,
        prefectureMatches: Bool,
        dateMatches: Bool,
        prefectureUnset: Bool = false,
        dateNeedsDiscussion: Bool = false,
        shippingFeeNeedsDiscussion: Bool = false,
        viewerExchangeMethodTitle: String? = nil,
        partnerExchangeMethodTitle: String? = nil,
        viewerLocalConditionText: String? = nil,
        partnerLocalConditionText: String? = nil,
        viewerShippingFeeTitle: String? = nil,
        partnerShippingFeeTitle: String? = nil,
        localRouteAvailable: Bool? = nil,
        localRoutePrefectureMatches: Bool? = nil,
        localRouteDateMatches: Bool? = nil,
        localRoutePrefectureUnset: Bool? = nil,
        localRouteDateNeedsDiscussion: Bool? = nil,
        partnerLocalPrefectures: Set<String> = [],
        partnerLocalDateKeys: Set<String> = [],
        matchedVenue: String? = nil,
        matchedLocalDateKeys: Set<String> = []
    ) {
        self.postalAcceptedByBoth = postalAcceptedByBoth
        self.localExchangeSelected = localExchangeSelected
        self.prefectureMatches = prefectureMatches
        self.dateMatches = dateMatches
        self.prefectureUnset = prefectureUnset
        self.dateNeedsDiscussion = dateNeedsDiscussion
        self.shippingFeeNeedsDiscussion = shippingFeeNeedsDiscussion
        self.viewerExchangeMethodTitle = viewerExchangeMethodTitle
        self.partnerExchangeMethodTitle = partnerExchangeMethodTitle
        self.viewerLocalConditionText = viewerLocalConditionText
        self.partnerLocalConditionText = partnerLocalConditionText
        self.viewerShippingFeeTitle = viewerShippingFeeTitle
        self.partnerShippingFeeTitle = partnerShippingFeeTitle
        self.localRouteAvailable = localRouteAvailable ?? localExchangeSelected
        self.localRoutePrefectureMatches = localRoutePrefectureMatches ?? prefectureMatches
        self.localRouteDateMatches = localRouteDateMatches ?? dateMatches
        self.localRoutePrefectureUnset = localRoutePrefectureUnset ?? prefectureUnset
        self.localRouteDateNeedsDiscussion = localRouteDateNeedsDiscussion ?? dateNeedsDiscussion
        self.partnerLocalPrefectures = Set(partnerLocalPrefectures.compactMap(Self.normalizedSettingText))
        self.partnerLocalDateKeys = Set(partnerLocalDateKeys)
        self.matchedVenue = matchedVenue.flatMap {
            let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        self.matchedLocalDateKeys = matchedLocalDateKeys
    }

    private static func normalizedSettingText(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}

public enum HomePaymentConditionStatus: String, Equatable, Sendable {
    case skipped
    case compatible
    case methodMismatch
    case viewerUnset
    case partnerUnset
    case unset
    case needsDiscussion
}

public struct HomePaymentConditionSignals: Equatable, Sendable {
    public var hasCompatiblePaymentMethod: Bool
    public var requiresPayment: Bool
    public var status: HomePaymentConditionStatus
    public var viewerMethods: [UserPaymentMethod]
    public var partnerMethods: [UserPaymentMethod]

    public init(
        hasCompatiblePaymentMethod: Bool,
        requiresPayment: Bool = false,
        status: HomePaymentConditionStatus? = nil,
        viewerMethods: [UserPaymentMethod] = [],
        partnerMethods: [UserPaymentMethod] = []
    ) {
        self.hasCompatiblePaymentMethod = hasCompatiblePaymentMethod
        self.requiresPayment = requiresPayment
        self.status = status ?? (hasCompatiblePaymentMethod ? .compatible : .methodMismatch)
        self.viewerMethods = UserPaymentMethod.normalized(viewerMethods)
        self.partnerMethods = UserPaymentMethod.normalized(partnerMethods)
    }

    public static var none: HomePaymentConditionSignals {
        HomePaymentConditionSignals(hasCompatiblePaymentMethod: false, status: .skipped)
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
    public var payment: HomePaymentConditionSignals
    public var linkCounts: HomeCandidateLinkCounts
    public var individualListingSelection: HomeIndividualListingSelectionContext?
    public var wishMatchedOfferGoodsIDs: [UUID]
    public var wishMatchedPartnerUserIDs: [UUID]
    public var matchesViewerWish: Bool
    public var matchesViewerWishCharacter: Bool
    public var tagMatchCount: Int
    public var ownerHasMegrumPlus: Bool

    public init(
        goods: HomeGoodsConditionSignals,
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals = .none,
        linkCounts: HomeCandidateLinkCounts = .zero,
        individualListingSelection: HomeIndividualListingSelectionContext? = nil,
        wishMatchedOfferGoodsIDs: [UUID] = [],
        wishMatchedPartnerUserIDs: [UUID] = [],
        matchesViewerWish: Bool = false,
        matchesViewerWishCharacter: Bool = false,
        tagMatchCount: Int = 0,
        ownerHasMegrumPlus: Bool = false
    ) {
        self.goods = goods
        self.exchange = exchange
        self.payment = payment
        self.linkCounts = linkCounts
        self.individualListingSelection = individualListingSelection
        self.wishMatchedOfferGoodsIDs = Self.orderedUnique(wishMatchedOfferGoodsIDs)
        self.wishMatchedPartnerUserIDs = Self.orderedUnique(wishMatchedPartnerUserIDs)
        self.matchesViewerWish = matchesViewerWish
        self.matchesViewerWishCharacter = matchesViewerWishCharacter
        self.tagMatchCount = max(0, tagMatchCount)
        self.ownerHasMegrumPlus = ownerHasMegrumPlus
    }

    private static func orderedUnique(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }
}
