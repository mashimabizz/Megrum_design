import Foundation

enum AdFormat: String, CaseIterable, Sendable {
    case banner
    case interstitial
    case native
}

enum AdProvider: String, CaseIterable, Sendable {
    case admob
    case direct
}

enum AdScreenTier: String, Sendable {
    case nativeInline
    case footerBanner
    case zeroAds
}

enum AdPlacement: String, CaseIterable, Identifiable, Sendable {
    case homeFeedBanner
    case wishListBanner
    case searchResultsBanner
    case publicProfileFooterBanner
    case pastTradesFooterBanner
    case homeBrowseInterstitial
    case wishBrowseInterstitial
    case searchBrowseInterstitial
    case meguriBrowseInterstitial

    var id: String { rawValue }

    var format: AdFormat {
        switch self {
        case .homeFeedBanner, .wishListBanner, .searchResultsBanner, .publicProfileFooterBanner, .pastTradesFooterBanner:
            .banner
        case .homeBrowseInterstitial, .wishBrowseInterstitial, .searchBrowseInterstitial, .meguriBrowseInterstitial:
            .interstitial
        }
    }

    var screenID: String {
        switch self {
        case .homeFeedBanner, .homeBrowseInterstitial:
            "HOM-main"
        case .wishListBanner, .wishBrowseInterstitial:
            "WSH-list"
        case .searchResultsBanner, .searchBrowseInterstitial:
            "SCH-main"
        case .publicProfileFooterBanner:
            "PRO-other"
        case .pastTradesFooterBanner:
            "TRD-past"
        case .meguriBrowseInterstitial:
            "MEG-main"
        }
    }

    var tier: AdScreenTier {
        switch self {
        case .homeFeedBanner, .wishListBanner, .searchResultsBanner:
            .nativeInline
        case .publicProfileFooterBanner, .pastTradesFooterBanner:
            .footerBanner
        case .homeBrowseInterstitial, .wishBrowseInterstitial, .searchBrowseInterstitial, .meguriBrowseInterstitial:
            .footerBanner
        }
    }

    var unitIDInfoKey: String {
        switch self {
        case .homeFeedBanner:
            "MegrumAdMobHomeBannerUnitID"
        case .wishListBanner:
            "MegrumAdMobWishBannerUnitID"
        case .searchResultsBanner:
            "MegrumAdMobSearchBannerUnitID"
        case .publicProfileFooterBanner:
            "MegrumAdMobProfileBannerUnitID"
        case .pastTradesFooterBanner:
            "MegrumAdMobTradesBannerUnitID"
        case .homeBrowseInterstitial:
            "MegrumAdMobHomeInterstitialUnitID"
        case .wishBrowseInterstitial:
            "MegrumAdMobWishInterstitialUnitID"
        case .searchBrowseInterstitial:
            "MegrumAdMobSearchInterstitialUnitID"
        case .meguriBrowseInterstitial:
            "MegrumAdMobMeguriInterstitialUnitID"
        }
    }

    static let zeroAdScreenIDs: Set<String> = [
        "AUTH",
        "ONB",
        "C0",
        "C1",
        "C15",
        "C2",
        "C3",
        "D",
        "RPT",
        "SET",
        "LEG",
        "HLP"
    ]
}

struct AdDisplayContext: Equatable, Sendable {
    var viewerID: UUID?
    var isPremiumSubscriber: Bool
    var adSuppressionUntil: Date?
    var now: Date

    init(
        viewerID: UUID? = nil,
        isPremiumSubscriber: Bool = false,
        adSuppressionUntil: Date? = nil,
        now: Date = Date()
    ) {
        self.viewerID = viewerID
        self.isPremiumSubscriber = isPremiumSubscriber
        self.adSuppressionUntil = adSuppressionUntil
        self.now = now
    }

    var hasActiveAdSuppression: Bool {
        guard let adSuppressionUntil else {
            return false
        }
        return adSuppressionUntil > now
    }
}

enum AdSuppressionReason: Error, Equatable, Sendable {
    case configurationDisabled
    case premiumSubscriber
    case activeAdOverride
    case forbiddenScreen
    case missingUnitID
    case frequencyCapped
}

struct AdDisplayDecision: Equatable, Sendable {
    var placement: AdPlacement
    var isAllowed: Bool
    var unitID: String?
    var usesPlaceholder: Bool
    var suppressionReason: AdSuppressionReason?

    static func allowed(
        placement: AdPlacement,
        unitID: String?,
        usesPlaceholder: Bool
    ) -> AdDisplayDecision {
        AdDisplayDecision(
            placement: placement,
            isAllowed: true,
            unitID: unitID,
            usesPlaceholder: usesPlaceholder,
            suppressionReason: nil
        )
    }

    static func suppressed(
        placement: AdPlacement,
        reason: AdSuppressionReason
    ) -> AdDisplayDecision {
        AdDisplayDecision(
            placement: placement,
            isAllowed: false,
            unitID: nil,
            usesPlaceholder: false,
            suppressionReason: reason
        )
    }
}

enum AdDisplayPolicy {
    static func decision(
        for placement: AdPlacement,
        context: AdDisplayContext,
        configuration: AdRuntimeConfiguration
    ) -> AdDisplayDecision {
        if AdPlacement.zeroAdScreenIDs.contains(where: { placement.screenID.hasPrefix($0) }) {
            return .suppressed(placement: placement, reason: .forbiddenScreen)
        }
        if context.isPremiumSubscriber {
            return .suppressed(placement: placement, reason: .premiumSubscriber)
        }
        if context.hasActiveAdSuppression {
            return .suppressed(placement: placement, reason: .activeAdOverride)
        }
        if !configuration.isEnabled && !configuration.showsPlaceholders {
            return .suppressed(placement: placement, reason: .configurationDisabled)
        }

        let unitID = configuration.unitID(for: placement)
        if unitID == nil && !configuration.showsPlaceholders {
            return .suppressed(placement: placement, reason: .missingUnitID)
        }

        return .allowed(
            placement: placement,
            unitID: unitID,
            usesPlaceholder: configuration.showsPlaceholders || unitID == nil
        )
    }
}
