import MegrumCore
import XCTest

final class SubscriptionModelsTests: XCTestCase {
    func testFreeStateDoesNotGrantPremiumEntitlements() {
        let state = UserSubscriptionState.free

        XCTAssertFalse(state.isPremiumActive)
        XCTAssertFalse(state.hasMeguriPlus)
        XCTAssertFalse(state.suppressesAds)
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
    }

    func testDefaultCatalogSeparatesPremiumAndMeguriPlus() {
        let premium = SubscriptionCatalog.defaultPlans.filter { $0.entitlementKey == .premium }
        let meguriPlus = SubscriptionCatalog.defaultPlans.filter { $0.entitlementKey == .meguriPlus }

        XCTAssertEqual(premium.count, 2)
        XCTAssertEqual(meguriPlus.count, 1)
        XCTAssertTrue(premium.allSatisfy { $0.featureIDs.contains(.adFree) })
        XCTAssertFalse(meguriPlus[0].featureIDs.contains(.adFree))
    }
}
