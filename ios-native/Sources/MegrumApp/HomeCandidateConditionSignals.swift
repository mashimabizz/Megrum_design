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
        localRouteDateNeedsDiscussion: Bool? = nil
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

public struct HomeIndividualListingOfferedItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var imageURL: URL?
    public var quantity: Int

    public init(
        id: UUID,
        title: String,
        imageURL: URL? = nil,
        quantity: Int = 1
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "グッズ"
        self.imageURL = imageURL
        self.quantity = max(1, quantity)
    }
}

public struct HomeIndividualListingDetailContext: Identifiable, Equatable, Sendable {
    public var listingID: UUID
    public var wantedLogic: ListingLogic
    public var offeredLogic: ListingLogic
    public var wantedMinimumCount: Int
    public var offeredMinimumCount: Int
    public var wantedOptions: [HomeIndividualListingWantedOption]
    public var offeredItems: [HomeIndividualListingOfferedItem]
    public var offeredCashAmount: Int?

    public var id: UUID { listingID }

    public init(
        listingID: UUID,
        wantedLogic: ListingLogic = .one,
        offeredLogic: ListingLogic = .all,
        wantedMinimumCount: Int = 1,
        offeredMinimumCount: Int = 1,
        wantedOptions: [HomeIndividualListingWantedOption] = [],
        offeredItems: [HomeIndividualListingOfferedItem] = [],
        offeredCashAmount: Int? = nil
    ) {
        self.listingID = listingID
        self.wantedLogic = wantedLogic
        self.offeredLogic = offeredLogic
        self.wantedMinimumCount = max(1, wantedMinimumCount)
        self.offeredMinimumCount = max(1, offeredMinimumCount)
        self.wantedOptions = wantedOptions
        self.offeredItems = offeredItems
        self.offeredCashAmount = offeredCashAmount.map { max(0, $0) }
    }
}

public struct HomeIndividualListingWantedPreviewItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var imageURL: URL?

    public init(
        id: UUID,
        title: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "グッズ"
        self.imageURL = imageURL
    }
}

public struct HomeIndividualListingSelectionContext: Equatable, Sendable {
    public var wantedLogic: ListingLogic
    public var offeredLogic: ListingLogic
    public var wantedMinimumCount: Int
    public var offeredMinimumCount: Int
    public var wantedOptions: [HomeIndividualListingWantedOption]
    public var listingNote: String?
    public var detail: HomeIndividualListingDetailContext?

    public init(
        wantedLogic: ListingLogic = .one,
        offeredLogic: ListingLogic = .all,
        wantedMinimumCount: Int = 1,
        offeredMinimumCount: Int = 1,
        wantedOptions: [HomeIndividualListingWantedOption] = [],
        listingNote: String? = nil,
        detail: HomeIndividualListingDetailContext? = nil
    ) {
        self.wantedLogic = wantedLogic
        self.offeredLogic = offeredLogic
        self.wantedMinimumCount = max(1, wantedMinimumCount)
        self.offeredMinimumCount = max(1, offeredMinimumCount)
        self.wantedOptions = wantedOptions
        self.listingNote = listingNote?.nilIfBlank
        self.detail = detail
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
    public var minimumCount: Int
    public var kind: Kind
    public var goodsIDs: [UUID]
    public var matchingGoodsIDs: [UUID]
    public var previewItems: [HomeIndividualListingWantedPreviewItem]
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
        minimumCount: Int = 1,
        kind: Kind,
        goodsIDs: [UUID] = [],
        matchingGoodsIDs: [UUID] = [],
        previewItems: [HomeIndividualListingWantedPreviewItem] = [],
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
        self.minimumCount = max(1, minimumCount)
        self.kind = kind
        self.goodsIDs = goodsIDs
        self.matchingGoodsIDs = matchingGoodsIDs
        self.previewItems = previewItems
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
    public var wishMatchedOfferGoodsIDs: [UUID]
    public var wishMatchedPartnerUserIDs: [UUID]
    public var matchesViewerWish: Bool
    public var matchesViewerWishCharacter: Bool
    public var tagMatchCount: Int

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
        tagMatchCount: Int = 0
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
