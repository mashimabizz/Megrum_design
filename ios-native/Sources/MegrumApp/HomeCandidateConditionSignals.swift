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
    /// 相手の発送目安（例: 2〜4日以内）。郵送行のサブに併記する。
    public var partnerShippingDaysTitle: String?
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
        partnerShippingDaysTitle: String? = nil,
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
        self.partnerShippingDaysTitle = partnerShippingDaysTitle
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
    /// 相手可視の受け取り銀行名（銀行振込の表示・同一銀行太字に使う）。
    public var partnerBankNames: [String]
    /// 自分の受け取り銀行名（同一銀行判定に使う）。
    public var viewerBankNames: [String]

    public init(
        hasCompatiblePaymentMethod: Bool,
        requiresPayment: Bool = false,
        status: HomePaymentConditionStatus? = nil,
        viewerMethods: [UserPaymentMethod] = [],
        partnerMethods: [UserPaymentMethod] = [],
        partnerBankNames: [String] = [],
        viewerBankNames: [String] = []
    ) {
        self.hasCompatiblePaymentMethod = hasCompatiblePaymentMethod
        self.requiresPayment = requiresPayment
        self.status = status ?? (hasCompatiblePaymentMethod ? .compatible : .methodMismatch)
        self.viewerMethods = UserPaymentMethod.normalized(viewerMethods)
        self.partnerMethods = UserPaymentMethod.normalized(partnerMethods)
        self.partnerBankNames = Self.cleanedBankNames(partnerBankNames)
        self.viewerBankNames = Self.cleanedBankNames(viewerBankNames)
    }

    /// 相手の銀行名のうち、自分の登録銀行と同じ銀行（太字対象）のキー集合。
    public var sharedBankMatchKeys: Set<String> {
        let viewerKeys = Set(viewerBankNames.compactMap { BankMaster.matchKey(displayName: $0) })
        return Set(partnerBankNames.compactMap { name in
            BankMaster.matchKey(displayName: name)
        }).intersection(viewerKeys)
    }

    private static func cleanedBankNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
                continue
            }
            result.append(trimmed)
        }
        return result
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
    /// 「求めてる？」用：相手のほしいものを条件型選択肢へ合成したもの（iter1226.417）。
    /// 個別募集の選択肢とは別枠で、需要判定（超求）には使わない。
    public var wishWantedOptions: [HomeIndividualListingWantedOption] = []
    public var wishMatchedOfferGoodsIDs: [UUID]
    /// wishMatchedOfferGoodsIDs のうち、シリーズ等が無記載で「確定」できない（＝不確定「？」）分。iter1226.363。
    public var wishTentativeOfferGoodsIDs: [UUID]
    public var wishMatchedPartnerUserIDs: [UUID]
    public var matchesViewerWish: Bool
    public var matchesViewerWishCharacter: Bool
    public var tagMatchCount: Int
    public var ownerHasMegrumPlus: Bool
    /// 相手の探し物（自分のグッズと合致しない時の需要行「〜を探し中」用）。
    public var partnerLookingForText: String?

    public init(
        goods: HomeGoodsConditionSignals,
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals = .none,
        linkCounts: HomeCandidateLinkCounts = .zero,
        individualListingSelection: HomeIndividualListingSelectionContext? = nil,
        wishWantedOptions: [HomeIndividualListingWantedOption] = [],
        wishMatchedOfferGoodsIDs: [UUID] = [],
        wishTentativeOfferGoodsIDs: [UUID] = [],
        wishMatchedPartnerUserIDs: [UUID] = [],
        matchesViewerWish: Bool = false,
        matchesViewerWishCharacter: Bool = false,
        tagMatchCount: Int = 0,
        ownerHasMegrumPlus: Bool = false,
        partnerLookingForText: String? = nil
    ) {
        self.goods = goods
        self.exchange = exchange
        self.payment = payment
        self.linkCounts = linkCounts
        self.individualListingSelection = individualListingSelection
        self.wishWantedOptions = wishWantedOptions
        self.wishMatchedOfferGoodsIDs = Self.orderedUnique(wishMatchedOfferGoodsIDs)
        self.wishTentativeOfferGoodsIDs = Self.orderedUnique(wishTentativeOfferGoodsIDs)
        self.wishMatchedPartnerUserIDs = Self.orderedUnique(wishMatchedPartnerUserIDs)
        self.matchesViewerWish = matchesViewerWish
        self.matchesViewerWishCharacter = matchesViewerWishCharacter
        self.tagMatchCount = max(0, tagMatchCount)
        self.ownerHasMegrumPlus = ownerHasMegrumPlus
        self.partnerLookingForText = partnerLookingForText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
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
