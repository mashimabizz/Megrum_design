import MegrumCore
import XCTest

final class SubscriptionModelsTests: XCTestCase {
    func testFreeStateDoesNotGrantPremiumEntitlements() {
        let state = UserSubscriptionState.free

        XCTAssertFalse(state.isPremiumActive)
        XCTAssertFalse(state.isMegrumPlusActive)
        XCTAssertFalse(state.hasMeguriPlus)
        XCTAssertFalse(state.hasMeguriMessageAccess)
        XCTAssertFalse(state.hasMeguriBoardExtendedAccess)
        XCTAssertFalse(state.suppressesAds)
        XCTAssertFalse(state.hasUnlimitedIndividualListings)
        XCTAssertFalse(state.prioritizesMatchDisplay)
        XCTAssertFalse(state.hasUnlimitedGroomArchive)
        XCTAssertTrue(state.activeEntitlements().isEmpty)
    }

    func testExpiredEntitlementIsNotEffective() {
        let now = Date(timeIntervalSince1970: 1_000)
        let state = UserSubscriptionState(
            entitlements: [
                UserEntitlement(
                    key: .premium,
                    isActive: true,
                    source: .subscription,
                    expiresAt: Date(timeIntervalSince1970: 999)
                )
            ]
        )

        XCTAssertFalse(state.hasActiveEntitlement(.premium, now: now))
    }

    func testPremiumEntitlementSuppressesAds() {
        let state = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .premium, isActive: true, source: .subscription)
            ]
        )

        XCTAssertTrue(state.isPremiumActive)
        XCTAssertTrue(state.suppressesAds)
        XCTAssertTrue(state.hasMeguriMessageAccess)
        XCTAssertTrue(state.hasMeguriBoardExtendedAccess)
    }

    func testMegrumPlusEntitlementUnlocksCurrentPaidFeatures() {
        let state = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .megrumPlus, isActive: true, source: .subscription)
            ]
        )

        XCTAssertTrue(state.isMegrumPlusActive)
        XCTAssertTrue(state.hasMeguriMessageAccess)
        XCTAssertTrue(state.hasMeguriBoardExtendedAccess)
        XCTAssertTrue(state.hasUnlimitedIndividualListings)
        XCTAssertTrue(state.prioritizesMatchDisplay)
        XCTAssertTrue(state.hasUnlimitedGroomArchive)
        XCTAssertFalse(state.suppressesAds)
    }

    func testDefaultCatalogUsesMegrumPlusAsCurrentPlan() {
        let plans = SubscriptionCatalog.defaultPlans
        let plan = plans.first

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plan?.planType, .megrumPlusMonthly)
        XCTAssertEqual(plan?.productID, SubscriptionCatalog.megrumPlusMonthlyProductID)
        XCTAssertEqual(plan?.displayName, "Megrumプレミアム")
        XCTAssertEqual(plan?.priceLabel, "月 ¥500")
        XCTAssertEqual(plan?.entitlementKey, .megrumPlus)
        XCTAssertEqual(Set(plan?.featureIDs ?? []), Set(SubscriptionCatalog.megrumPlusFeatures))
        XCTAssertNotNil(SubscriptionCatalog.plan(for: SubscriptionCatalog.premiumMonthlyProductID))
    }

    func testLegacyMeguriPlusEntitlementUnlocksMeguriMessagesAndBoardAccessOnly() {
        let state = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .meguriPlus, isActive: true, source: .subscription)
            ]
        )

        XCTAssertTrue(state.hasMeguriPlus)
        XCTAssertTrue(state.hasMeguriMessageAccess)
        XCTAssertTrue(state.hasMeguriBoardExtendedAccess)
        XCTAssertFalse(state.isMegrumPlusActive)
        XCTAssertFalse(state.hasUnlimitedIndividualListings)
        XCTAssertFalse(state.hasUnlimitedGroomArchive)
    }
}
