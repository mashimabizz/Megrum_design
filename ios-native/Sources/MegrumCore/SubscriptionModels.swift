import Foundation

public enum SubscriptionPlanType: String, Codable, Sendable, CaseIterable, Identifiable {
    case megrumPlusMonthly = "megrum_plus_monthly"
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    case meguriPlusMonthly = "meguri_plus_monthly"
    case monthly
    case yearly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .megrumPlusMonthly:
            "\(SubscriptionCatalog.currentPremiumDisplayName) 月額"
        case .premiumMonthly:
            "Premium 月額"
        case .premiumYearly:
            "Premium 年額"
        case .meguriPlusMonthly:
            "めぐりPlus 月額"
        case .monthly:
            "月額"
        case .yearly:
            "年額"
        }
    }
}

public enum SubscriptionStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case incomplete
    case incompleteExpired = "incomplete_expired"
    case trialing
    case active
    case pastDue = "past_due"
    case cancelled
    case canceled
    case unpaid
    case expired

    public var id: String { rawValue }

    public var isAccessMaintained: Bool {
        switch self {
        case .trialing, .active, .pastDue, .cancelled:
            true
        case .incomplete, .incompleteExpired, .canceled, .unpaid, .expired:
            false
        }
    }
}

public enum UserEntitlementKey: String, Codable, Sendable, CaseIterable, Identifiable {
    case megrumPlus = "megrum_plus"
    case premium
    case meguriPlus = "meguri_plus"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .megrumPlus:
            SubscriptionCatalog.currentPremiumDisplayName
        case .premium:
            "Premium 会員"
        case .meguriPlus:
            "めぐりPlus"
        }
    }
}

public enum UserEntitlementSource: String, Codable, Sendable, CaseIterable, Identifiable {
    case subscription
    case manualOverride = "manual_override"
    case system
    case purchase

    public var id: String { rawValue }
}

public struct UserEntitlement: Identifiable, Codable, Hashable, Sendable {
    public var key: UserEntitlementKey
    public var isActive: Bool
    public var source: UserEntitlementSource
    public var grantedAt: Date?
    public var expiresAt: Date?
    public var updatedAt: Date?

    public var id: UserEntitlementKey { key }

    public init(
        key: UserEntitlementKey,
        isActive: Bool,
        source: UserEntitlementSource,
        grantedAt: Date? = nil,
        expiresAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.key = key
        self.isActive = isActive
        self.source = source
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.updatedAt = updatedAt
    }

    public func isEffective(now: Date = Date()) -> Bool {
        guard isActive else {
            return false
        }
        guard let expiresAt else {
            return true
        }
        return expiresAt > now
    }
}

public struct MegrumPlusPurchaseSyncInput: Codable, Hashable, Sendable {
    public var productID: String
    public var transactionID: String
    public var originalTransactionID: String
    public var expiresAt: Date?
    public var verifiedAt: Date

    public init(
        productID: String,
        transactionID: String,
        originalTransactionID: String,
        expiresAt: Date? = nil,
        verifiedAt: Date = Date()
    ) {
        self.productID = productID
        self.transactionID = transactionID
        self.originalTransactionID = originalTransactionID
        self.expiresAt = expiresAt
        self.verifiedAt = verifiedAt
    }
}

public struct UserSubscriptionState: Codable, Hashable, Sendable {
    public var planType: SubscriptionPlanType?
    public var status: SubscriptionStatus?
    public var currentPeriodEnd: Date?
    public var cancelledAt: Date?
    public var entitlements: [UserEntitlement]
    public var loadedAt: Date?

    public init(
        planType: SubscriptionPlanType? = nil,
        status: SubscriptionStatus? = nil,
        currentPeriodEnd: Date? = nil,
        cancelledAt: Date? = nil,
        entitlements: [UserEntitlement] = [],
        loadedAt: Date? = nil
    ) {
        self.planType = planType
        self.status = status
        self.currentPeriodEnd = currentPeriodEnd
        self.cancelledAt = cancelledAt
        self.entitlements = entitlements
        self.loadedAt = loadedAt
    }

    public static let free = UserSubscriptionState()

    public func hasActiveEntitlement(_ key: UserEntitlementKey, now: Date = Date()) -> Bool {
        entitlements.contains { entitlement in
            entitlement.key == key && entitlement.isEffective(now: now)
        }
    }

    public func activeEntitlements(now: Date = Date()) -> [UserEntitlement] {
        entitlements.filter { $0.isEffective(now: now) }
    }

    public var isPremiumActive: Bool {
        hasActiveEntitlement(.premium)
    }

    public var isMegrumPlusActive: Bool {
        hasActiveEntitlement(.megrumPlus)
    }

    public var hasMeguriPlus: Bool {
        hasActiveEntitlement(.meguriPlus)
    }

    public var hasMeguriMessageAccess: Bool {
        isMegrumPlusActive || hasMeguriPlus || isPremiumActive
    }

    public var hasMeguriBoardExtendedAccess: Bool {
        isMegrumPlusActive || hasMeguriPlus || isPremiumActive
    }

    public var hasUnlimitedIndividualListings: Bool {
        isMegrumPlusActive
    }

    public var prioritizesMatchDisplay: Bool {
        isMegrumPlusActive
    }

    public var hasUnlimitedGroomArchive: Bool {
        isMegrumPlusActive
    }

    public var suppressesAds: Bool {
        isPremiumActive
    }
}

public enum MonetizationFeature: String, Codable, Sendable, CaseIterable, Identifiable {
    case unlimitedIndividualListings = "unlimited_individual_listings"
    case priorityMatchDisplay = "priority_match_display"
    case unlimitedGroomArchive = "unlimited_groom_archive"
    case adFree = "ad_free"
    case monthlyBoostGrant = "monthly_boost_grant"
    case extendedMessageHistory = "extended_message_history"
    case readReceipts = "read_receipts"
    case profileCustomization = "profile_customization"
    case profileBadge = "profile_badge"
    case savedSearchSlots = "saved_search_slots"
    case meguriMessageExpansion = "meguri_message_expansion"
    case meguriBoardExtendedAccess = "meguri_board_extended_access"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .unlimitedIndividualListings:
            "個別募集の作成数が無制限"
        case .priorityMatchDisplay:
            "ホーム・検索で自分のグッズを優先表示"
        case .unlimitedGroomArchive:
            "グルームアーカイブが無制限"
        case .adFree:
            "広告非表示"
        case .monthlyBoostGrant:
            "月次ブースト付与"
        case .extendedMessageHistory:
            "メッセージ履歴拡張"
        case .readReceipts:
            "既読確認"
        case .profileCustomization:
            "プロフィール装飾"
        case .profileBadge:
            "Premiumバッジ"
        case .savedSearchSlots:
            "保存検索枠拡張"
        case .meguriMessageExpansion:
            "めぐり内でメッセージのやり取りが可能"
        case .meguriBoardExtendedAccess:
            "県外の掲示板も閲覧可能"
        }
    }
}

public struct SubscriptionPlanDefinition: Identifiable, Codable, Hashable, Sendable {
    public var planType: SubscriptionPlanType
    public var productID: String
    public var displayName: String
    public var priceLabel: String
    public var featureIDs: [MonetizationFeature]
    public var entitlementKey: UserEntitlementKey
    public var sortOrder: Int

    public var id: SubscriptionPlanType { planType }

    public init(
        planType: SubscriptionPlanType,
        productID: String,
        displayName: String,
        priceLabel: String,
        featureIDs: [MonetizationFeature],
        entitlementKey: UserEntitlementKey,
        sortOrder: Int
    ) {
        self.planType = planType
        self.productID = productID
        self.displayName = displayName
        self.priceLabel = priceLabel
        self.featureIDs = featureIDs
        self.entitlementKey = entitlementKey
        self.sortOrder = sortOrder
    }
}

public enum SubscriptionCatalog {
    public static let currentPremiumDisplayName = "Megrumプレミアム"
    public static let megrumPlusMonthlyProductID = "megrum.plus.monthly"
    public static let premiumMonthlyProductID = "megrum.premium.monthly"
    public static let premiumYearlyProductID = "megrum.premium.yearly"
    public static let meguriPlusMonthlyProductID = "megrum.meguri_plus.monthly"

    public static let defaultPlans: [SubscriptionPlanDefinition] = [
        SubscriptionPlanDefinition(
            planType: .megrumPlusMonthly,
            productID: megrumPlusMonthlyProductID,
            displayName: currentPremiumDisplayName,
            priceLabel: "月 ¥500",
            featureIDs: megrumPlusFeatures,
            entitlementKey: .megrumPlus,
            sortOrder: 10
        )
    ]

    public static let legacyPlans: [SubscriptionPlanDefinition] = [
        SubscriptionPlanDefinition(
            planType: .premiumMonthly,
            productID: premiumMonthlyProductID,
            displayName: "Premium 月額",
            priceLabel: "月 ¥500",
            featureIDs: premiumFeatures,
            entitlementKey: .premium,
            sortOrder: 10
        ),
        SubscriptionPlanDefinition(
            planType: .premiumYearly,
            productID: premiumYearlyProductID,
            displayName: "Premium 年額",
            priceLabel: "年 ¥4,800",
            featureIDs: premiumFeatures,
            entitlementKey: .premium,
            sortOrder: 20
        ),
        SubscriptionPlanDefinition(
            planType: .meguriPlusMonthly,
            productID: meguriPlusMonthlyProductID,
            displayName: "めぐりPlus 月額",
            priceLabel: "月 ¥1,000",
            featureIDs: [.meguriMessageExpansion],
            entitlementKey: .meguriPlus,
            sortOrder: 120
        )
    ]

    public static let megrumPlusFeatures: [MonetizationFeature] = [
        .unlimitedIndividualListings,
        .priorityMatchDisplay,
        .unlimitedGroomArchive,
        .meguriMessageExpansion,
        .meguriBoardExtendedAccess
    ]

    public static let premiumFeatures: [MonetizationFeature] = [
        .adFree,
        .monthlyBoostGrant,
        .extendedMessageHistory,
        .readReceipts,
        .profileCustomization,
        .profileBadge,
        .savedSearchSlots
    ]

    public static func plan(for productID: String) -> SubscriptionPlanDefinition? {
        (defaultPlans + legacyPlans).first { $0.productID == productID }
    }
}

public enum MegrumPlusLimits {
    public static let freeIndividualListingLimit = 3
    public static let freeGroomArchiveLimit = 10
    public static let defaultGroomArchivePageLimit = 120
    public static let monthlyPriceLabel = "月 ¥500"
}
