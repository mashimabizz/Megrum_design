@testable import MegrumApp
import MegrumCore
import XCTest

final class AdDisplayPolicyTests: XCTestCase {
    func testAdsStayDisabledByDefault() {
        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(),
            configuration: .disabled
        )

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.suppressionReason, .configurationDisabled)
    }

    func testConfiguredBannerPlacementIsAllowedForFreeViewer() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            unitIDs: [.homeFeedBanner: "ca-app-pub-home"]
        )

        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertEqual(decision.unitID, "ca-app-pub-home")
        XCTAssertFalse(decision.usesPlaceholder)
    }

    func testPlaceholderModeAllowsLayoutWithoutRealUnitID() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: false,
            showsPlaceholders: true
        )

        let decision = AdDisplayPolicy.decision(
            for: .wishListBanner,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertTrue(decision.usesPlaceholder)
    }

    func testPremiumAndActiveOverridesSuppressAds() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            unitIDs: [.searchResultsBanner: "ca-app-pub-search"]
        )

        let premiumDecision = AdDisplayPolicy.decision(
            for: .searchResultsBanner,
            context: AdDisplayContext(isPremiumSubscriber: true),
            configuration: configuration
        )
        XCTAssertFalse(premiumDecision.isAllowed)
        XCTAssertEqual(premiumDecision.suppressionReason, .premiumSubscriber)

        let overrideDecision = AdDisplayPolicy.decision(
            for: .searchResultsBanner,
            context: AdDisplayContext(
                adSuppressionUntil: Date(timeIntervalSince1970: 200),
                now: Date(timeIntervalSince1970: 100)
            ),
            configuration: configuration
        )
        XCTAssertFalse(overrideDecision.isAllowed)
        XCTAssertEqual(overrideDecision.suppressionReason, .activeAdOverride)
    }

    func testSubscriptionStateCanDrivePremiumAdSuppression() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            unitIDs: [.homeFeedBanner: "ca-app-pub-home"]
        )
        let subscriptionState = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .premium, isActive: true, source: .subscription)
            ]
        )

        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(isPremiumSubscriber: subscriptionState.suppressesAds),
            configuration: configuration
        )

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.suppressionReason, .premiumSubscriber)
    }

    func testInterstitialResolverAvoidsInventoryAndTrades() {
        XCTAssertEqual(AdInterstitialPlacementResolver.placement(for: .home), .homeBrowseInterstitial)
        XCTAssertEqual(AdInterstitialPlacementResolver.placement(for: .wish), .wishBrowseInterstitial)
        XCTAssertEqual(AdInterstitialPlacementResolver.placement(for: .meguri), .meguriBrowseInterstitial)
        XCTAssertNil(AdInterstitialPlacementResolver.placement(for: .inventory))
        XCTAssertNil(AdInterstitialPlacementResolver.placement(for: .trades))
    }

    func testInterstitialCoordinatorAppliesCooldown() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            unitIDs: [.homeBrowseInterstitial: "ca-app-pub-interstitial"]
        )
        let firstRequest = AdInterstitialRequest(
            placement: .homeBrowseInterstitial,
            requestedAt: Date(timeIntervalSince1970: 1_000)
        )
        let firstResult = AdInterstitialCoordinator.presentation(
            for: firstRequest,
            context: AdDisplayContext(now: firstRequest.requestedAt),
            configuration: configuration,
            lastPresentedAt: nil
        )
        XCTAssertNotNil(try? firstResult.get())

        let secondRequest = AdInterstitialRequest(
            placement: .homeBrowseInterstitial,
            requestedAt: Date(timeIntervalSince1970: 1_060)
        )
        let secondResult = AdInterstitialCoordinator.presentation(
            for: secondRequest,
            context: AdDisplayContext(now: secondRequest.requestedAt),
            configuration: configuration,
            lastPresentedAt: firstRequest.requestedAt
        )

        XCTAssertThrowsError(try secondResult.get()) { error in
            XCTAssertEqual(error as? AdSuppressionReason, .frequencyCapped)
        }
    }

    func testRuntimeConfigurationIgnoresUnresolvedBuildSettings() {
        let configuration = AdRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: [
                "MegrumAdsEnabled": "YES",
                "MegrumAdPlaceholdersEnabled": "NO",
                "MegrumAdMobHomeBannerUnitID": "$(MEGRUM_ADMOB_HOME_BANNER_UNIT_ID)"
            ]
        )

        XCTAssertTrue(configuration.isEnabled)
        XCTAssertNil(configuration.unitID(for: .homeFeedBanner))
    }
}
