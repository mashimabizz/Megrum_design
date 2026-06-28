@testable import MegrumApp
import MegrumCore
import XCTest

final class AdDisplayPolicyTests: XCTestCase {
    private let michilionUserID = UUID(uuidString: "72ea1426-24ce-46b3-a22f-886c67498b02")!

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
            unitIDs: [.tradesListTopBanner: "ca-app-pub-trades"]
        )

        let decision = AdDisplayPolicy.decision(
            for: .tradesListTopBanner,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertEqual(decision.unitID, "ca-app-pub-trades")
        XCTAssertFalse(decision.usesPlaceholder)
    }

    func testTradesTopBannerUsesConfiguredScreenAndEnvironmentKeys() {
        XCTAssertEqual(AdPlacement.tradesListTopBanner.screenID, "TRD-list")
        XCTAssertEqual(AdPlacement.tradesListTopBanner.tier.rawValue, AdScreenTier.nativeInline.rawValue)
        XCTAssertEqual(
            AdRuntimeConfiguration.environmentKey(for: .tradesListTopBanner),
            "MEGRUM_ADMOB_TRADES_BANNER_UNIT_ID"
        )
    }

    func testSearchResultsNativePlacementUsesSearchScreenAndNativeFormat() {
        XCTAssertEqual(AdPlacement.searchResultsNative.screenID, "SCH-main")
        XCTAssertEqual(AdPlacement.searchResultsNative.format, .native)
        XCTAssertEqual(AdPlacement.searchResultsNative.tier, .nativeInline)
        XCTAssertEqual(
            AdRuntimeConfiguration.environmentKey(for: .searchResultsNative),
            "MEGRUM_ADMOB_SEARCH_NATIVE_UNIT_ID"
        )
    }

    func testGoogleTestBannerOverridesConfiguredBannerUnitWhenEnabled() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            usesGoogleTestAdUnits: true,
            unitIDs: [.tradesListTopBanner: "ca-app-pub-production"]
        )

        let decision = AdDisplayPolicy.decision(
            for: .tradesListTopBanner,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertEqual(decision.unitID, AdRuntimeConfiguration.googleDemoBannerUnitID)
        XCTAssertFalse(decision.usesPlaceholder)
    }

    func testGoogleTestNativeOverridesConfiguredNativeUnitWhenEnabled() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            usesGoogleTestAdUnits: true,
            unitIDs: [.searchResultsNative: "ca-app-pub-production-native"]
        )

        let decision = AdDisplayPolicy.decision(
            for: .searchResultsNative,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertEqual(decision.unitID, AdRuntimeConfiguration.googleDemoNativeUnitID)
        XCTAssertFalse(decision.usesPlaceholder)
    }

    func testGoogleTestBannerDoesNotCreateUnconfiguredPlacements() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            usesGoogleTestAdUnits: true,
            unitIDs: [.tradesListTopBanner: "ca-app-pub-production"]
        )

        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(),
            configuration: configuration
        )

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.suppressionReason, .missingUnitID)
    }

    func testPreviewViewerCanSeeHomeBannerUsingGoogleTestAdFallback() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            usesGoogleTestAdUnits: true,
            unitIDs: [:],
            previewViewerIDs: [michilionUserID]
        )

        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(viewerID: michilionUserID),
            configuration: configuration
        )

        XCTAssertTrue(decision.isAllowed)
        XCTAssertEqual(decision.unitID, AdRuntimeConfiguration.googleDemoBannerUnitID)
        XCTAssertFalse(decision.usesPlaceholder)
    }

    func testPreviewViewerFallbackDoesNotEnableHomeBannerForOtherViewers() {
        let configuration = AdRuntimeConfiguration(
            isEnabled: true,
            usesGoogleTestAdUnits: true,
            unitIDs: [:],
            previewViewerIDs: [michilionUserID]
        )

        let decision = AdDisplayPolicy.decision(
            for: .homeFeedBanner,
            context: AdDisplayContext(viewerID: UUID(uuidString: "00000000-0000-0000-0000-000000000999")),
            configuration: configuration
        )

        XCTAssertFalse(decision.isAllowed)
        XCTAssertEqual(decision.suppressionReason, .missingUnitID)
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
            unitIDs: [.tradesListTopBanner: "ca-app-pub-trades"]
        )
        let subscriptionState = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .premium, isActive: true, source: .subscription)
            ]
        )

        let decision = AdDisplayPolicy.decision(
            for: .tradesListTopBanner,
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

    func testRuntimeConfigurationReadsSearchNativeUnitIDAndNativeTestUnitID() {
        let configuration = AdRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: [
                "MegrumAdsEnabled": "YES",
                "MegrumAdMobTestAdsEnabled": "YES",
                "MegrumAdMobTestNativeUnitID": "ca-app-pub-test/native",
                "MegrumAdMobSearchNativeUnitID": "ca-app-pub-production/native"
            ]
        )

        XCTAssertEqual(configuration.unitID(for: .searchResultsNative), "ca-app-pub-test/native")
    }

    func testRuntimeConfigurationReadsPreviewViewerIDs() {
        let configuration = AdRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: [
                "MegrumAdPreviewViewerIDs": "\(michilionUserID), 00000000-0000-0000-0000-000000000111"
            ]
        )

        XCTAssertTrue(configuration.isPreviewViewer(michilionUserID))
        XCTAssertTrue(configuration.isPreviewViewer(UUID(uuidString: "00000000-0000-0000-0000-000000000111")))
        XCTAssertFalse(configuration.isPreviewViewer(UUID(uuidString: "00000000-0000-0000-0000-000000000222")))
    }

    func testRuntimeConfigurationReadsOfficialAdMobAppIDKey() {
        let configuration = AdRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: [
                "MegrumAdsEnabled": "YES",
                "MegrumAdPlaceholdersEnabled": "NO",
                "MegrumAdProvider": "admob",
                "GADApplicationIdentifier": "ca-app-pub-demo~app"
            ]
        )

        XCTAssertEqual(configuration.appID, "ca-app-pub-demo~app")
        XCTAssertTrue(configuration.shouldStartAdMobSDK)
    }
}
