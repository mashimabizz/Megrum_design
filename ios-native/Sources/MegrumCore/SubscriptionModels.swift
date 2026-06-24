import Foundation

public enum SubscriptionPlanType: String, Codable, Sendable, CaseIterable, Identifiable {
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    case meguriPlusMonthly = "meguri_plus_monthly"
    case monthly
    case yearly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
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
    case premium
    case meguriPlus = "meguri_plus"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
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

    public var hasMeguriPlus: Bool {
        hasActiveEntitlement(.meguriPlus)
    }

    public var suppressesAds: Bool {
        isPremiumActive
    }
}

public enum MonetizationFeature: String, Codable, Sendable, CaseIterable, Identifiable {
    case adFree = "ad_free"
    case monthlyBoostGrant = "monthly_boost_grant"
    case extendedMessageHistory = "extended_message_history"
    case readReceipts = "read_receipts"
    case profileCustomization = "profile_customization"
    case profileBadge = "profile_badge"
    case savedSearchSlots = "saved_search_slots"
    case meguriMessageExpansion = "meguri_message_expansion"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
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
            "めぐり送信枠拡張"
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
    public static let premiumMonthlyProductID = "megrum.premium.monthly"
    public static let premiumYearlyProductID = "megrum.premium.yearly"
    public static let meguriPlusMonthlyProductID = "megrum.meguri_plus.monthly"

    public static let defaultPlans: [SubscriptionPlanDefinition] = [
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
            sortOrder: 30
        )
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
        defaultPlans.first { $0.productID == productID }
    }
}
