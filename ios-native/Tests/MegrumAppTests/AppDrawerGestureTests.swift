@testable import MegrumApp
import MegrumCore
import XCTest

final class AppDrawerGestureTests: XCTestCase {
    func testDrawerItemsMatchRnProfileDrawerOrder() {
        XCTAssertEqual(
            AppDrawerDestination.primaryItems.map(\.title),
            [
                "プロフィール",
                "通知",
                "推し設定",
                "支払い方法の設定",
                "交換条件の設定"
            ]
        )
        XCTAssertEqual(
            AppDrawerDestination.compactItems.map(\.title),
            [
                "設定とプライバシー",
                "ヘルプ"
            ]
        )
    }

    func testDrawerSettingsBadgesRequireMissingExchangeAndPaymentSettings() {
        let todayKey = HomeExchangeDateKey.key(for: Date())
        XCTAssertEqual(
            AppDrawerSettingsBadgePolicy.exchangeBadgeText(
                settings: HomeDefaultExchangeSettings(
                    preference: .both,
                    localPrefecture: "東京都",
                    localDateKeys: [todayKey]
                ),
                isExplicitlyConfigured: false
            ),
            "要設定"
        )
        XCTAssertNil(
            AppDrawerSettingsBadgePolicy.exchangeBadgeText(
                settings: HomeDefaultExchangeSettings(
                    preference: .both,
                    localPrefecture: "東京都",
                    localDateKeys: [todayKey]
                ),
                isExplicitlyConfigured: true
            )
        )
        XCTAssertEqual(
            AppDrawerSettingsBadgePolicy.paymentBadgeText(methods: []),
            "要設定"
        )
        XCTAssertNil(
            AppDrawerSettingsBadgePolicy.paymentBadgeText(methods: [.paypay])
        )
        XCTAssertNil(
            AppDrawerSettingsBadgePolicy.paymentBadgeText(methods: [], hasAnyStoredData: true)
        )
    }

    func testDrawerExchangeBadgeRequiresFutureLocalDateForLocalMethods() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let expiredKey = HomeExchangeDateKey.key(for: yesterday, calendar: calendar)

        XCTAssertEqual(
            AppDrawerSettingsBadgePolicy.exchangeBadgeText(
                settings: HomeDefaultExchangeSettings(
                    preference: .local,
                    localPrefecture: "東京都",
                    localDateKeys: [expiredKey]
                ),
                isExplicitlyConfigured: true
            ),
            "要設定"
        )
        XCTAssertNil(
            AppDrawerSettingsBadgePolicy.exchangeBadgeText(
                settings: HomeDefaultExchangeSettings(
                    preference: .mail,
                    localPrefecture: "",
                    localDateKeys: []
                ),
                isExplicitlyConfigured: true
            )
        )
    }

    func testDrawerVisualMetricsMatchRnXStyleForegroundPush() {
        XCTAssertEqual(AppDrawerVisualMetrics.minimumDrawerWidth, 320)
        XCTAssertEqual(AppDrawerVisualMetrics.maximumDrawerWidth, 380)
        XCTAssertEqual(AppDrawerVisualMetrics.drawerWidthRatio, 0.9)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundOpenRatio, 0.68)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundOpenInset, 34)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundCornerRadius, 18)
        XCTAssertEqual(AppDrawerVisualMetrics.whiteoutOpacity, 0.18)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundShadowOpacity, 0.16)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundZIndex, 1)
        XCTAssertEqual(AppDrawerVisualMetrics.closedEdgeGestureZIndex, 8)
        XCTAssertEqual(AppDrawerVisualMetrics.drawerZIndex, 10)
        XCTAssertEqual(AppDrawerVisualMetrics.closedEdgeGestureWidth, 28)
        XCTAssertEqual(
            AppDrawerVisualMetrics.drawerWidth(screenWidth: 402),
            361.8,
            accuracy: 0.01
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.openOffset(screenWidth: 402),
            273.36,
            accuracy: 0.01
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.drawerOffset(drawerWidth: 361.8, progress: 0),
            -361.8,
            accuracy: 0.01
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.drawerOffset(drawerWidth: 361.8, progress: 0.5),
            -180.9,
            accuracy: 0.01
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.drawerOffset(drawerWidth: 361.8, progress: 1),
            0,
            accuracy: 0.01
        )
    }

    func testDrawerLayeringKeepsVisibleDrawerTouchableAbovePushedForeground() {
        XCTAssertGreaterThan(
            AppDrawerVisualMetrics.drawerZIndex,
            AppDrawerVisualMetrics.foregroundZIndex
        )
        XCTAssertGreaterThan(
            AppDrawerVisualMetrics.closedEdgeGestureZIndex,
            AppDrawerVisualMetrics.foregroundZIndex
        )
    }

    func testDrawerPresentationProgressTracksContentAndDrawerTogether() {
        XCTAssertEqual(
            AppDrawerVisualMetrics.presentationProgress(
                isPresented: false,
                dragTranslation: 80,
                drawerTravel: 200
            ),
            0.4,
            accuracy: 0.001
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.presentationProgress(
                isPresented: true,
                dragTranslation: -80,
                drawerTravel: 200
            ),
            0.6,
            accuracy: 0.001
        )
        XCTAssertEqual(
            AppDrawerVisualMetrics.presentationProgress(
                isPresented: true,
                dragTranslation: 80,
                drawerTravel: 200
            ),
            1,
            accuracy: 0.001
        )
    }

    func testClosedDrawerRevealDoesNotRunAheadOfFingerTranslation() {
        let presentation = AppDrawerPresentationState(
            containerWidth: 402,
            isPresented: false,
            dragTranslation: 54
        )
        let drawerRightEdge = presentation.drawerWidth
            + AppDrawerVisualMetrics.drawerOffset(
                drawerWidth: presentation.drawerWidth,
                progress: presentation.progress
            )

        XCTAssertEqual(drawerRightEdge, 54, accuracy: 0.01)
        XCTAssertLessThanOrEqual(drawerRightEdge, 54.01)
        XCTAssertEqual(
            presentation.contentOffset,
            AppDrawerVisualMetrics.openOffset(screenWidth: 402) * (CGFloat(54) / 361.8),
            accuracy: 0.01
        )
    }

    func testClosedDrawerStartsTrackingOnHorizontalRightSwipe() {
        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: false,
            translation: CGSize(width: 6, height: 1)
        )

        XCTAssertEqual(translation, 6)
    }

    func testClosedDrawerTranslationStillOnlyChecksDirection() {
        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: false,
            translation: CGSize(width: 54, height: 6)
        )

        XCTAssertEqual(translation, 54)
    }

    func testClosedHomeDrawerSwipeStartsOnlyFromLeadingEdge() {
        let screenSize = CGSize(width: 402, height: 874)

        XCTAssertTrue(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 18, y: 402),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 201, y: 180),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 30, y: 402),
                screenSize: screenSize
            )
        )
    }

    func testClosedHomeDrawerSwipeDoesNotStartFromGoodsImageOrTabContent() {
        let screenSize = CGSize(width: 402, height: 874)

        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 88, y: 180),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 300, y: 402),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: CGPoint(x: 201, y: 402),
                screenSize: screenSize
            )
        )
    }

    func testClosedHomeDrawerSwipeIsDisabledWhileSearchIsPresented() {
        let screenSize = CGSize(width: 402, height: 874)
        let allowedHomeStart = CGPoint(x: 18, y: 180)

        XCTAssertTrue(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: false,
                startLocation: allowedHomeStart,
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: true,
                isDrawerPresented: false,
                isSearchPresented: true,
                startLocation: allowedHomeStart,
                screenSize: screenSize
            )
        )
    }

    func testOpenDrawerLeftSwipeCanStartAnywhereInsideScreen() {
        let screenSize = CGSize(width: 402, height: 874)

        XCTAssertTrue(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: 44, y: 96),
                screenSize: screenSize
            )
        )
        XCTAssertTrue(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: 220, y: 430),
                screenSize: screenSize
            )
        )
        XCTAssertTrue(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: 360, y: 820),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: -1, y: 430),
                screenSize: screenSize
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: 220, y: 875),
                screenSize: screenSize
            )
        )
    }

    func testOpenDrawerStillClosesFromFullScreenLeftSwipe() {
        let screenSize = CGSize(width: 402, height: 874)

        XCTAssertTrue(
            AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                startLocation: CGPoint(x: 360, y: 820),
                screenSize: screenSize
            )
        )

        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: true,
            translation: CGSize(width: -110, height: 7)
        )
        let targetVisibility = AppDrawerGestureResolver.targetVisibility(
            isPresented: true,
            translation: CGSize(width: -110, height: 7),
            predictedEndTranslationWidth: -146,
            drawerWidth: 320
        )

        XCTAssertEqual(translation, -110)
        XCTAssertEqual(targetVisibility, false)
    }

    func testDrawerGestureThresholdsMatchRnPanResponderModel() {
        XCTAssertEqual(AppDrawerGestureResolver.closedStartMinimumDistance, 5)
        XCTAssertEqual(AppDrawerGestureResolver.openStartMinimumDistance, 6)
        XCTAssertEqual(AppDrawerGestureResolver.closedHorizontalDominance, 1)
        XCTAssertEqual(AppDrawerGestureResolver.openHorizontalDominance, 1)
        XCTAssertEqual(AppDrawerGestureResolver.openThresholdRatio, 0.24)
        XCTAssertEqual(AppDrawerGestureResolver.predictedMomentumBonus, 32)
        XCTAssertEqual(AppDrawerGestureResolver.drawerItemTapSuppressionDistance, 8)
        XCTAssertEqual(AppDrawerGestureResolver.drawerItemTapSuppressionDuration, 0.28)
    }

    func testDrawerItemTapIsSuppressedOnlyAfterRealDrag() {
        XCTAssertTrue(
            AppDrawerGestureResolver.shouldSuppressDrawerItemTap(
                translation: CGSize(width: -36, height: 2)
            )
        )
        XCTAssertTrue(
            AppDrawerGestureResolver.shouldSuppressDrawerItemTap(
                translation: CGSize(width: 1, height: 12)
            )
        )
        XCTAssertFalse(
            AppDrawerGestureResolver.shouldSuppressDrawerItemTap(
                translation: CGSize(width: -4, height: 2)
            )
        )
    }

    func testClosedDrawerIgnoresVerticalSwipe() {
        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: false,
            translation: CGSize(width: 18, height: 24)
        )

        XCTAssertNil(translation)
    }

    func testClosedDrawerIgnoresLeftSwipeAndStaysClosedBelowThreshold() {
        XCTAssertNil(
            AppDrawerGestureResolver.activeTranslation(
                isPresented: false,
                translation: CGSize(width: -48, height: 4)
            )
        )

        let targetVisibility = AppDrawerGestureResolver.targetVisibility(
            isPresented: false,
            translation: CGSize(width: 64, height: 4),
            predictedEndTranslationWidth: 76,
            drawerWidth: 273.36
        )

        XCTAssertEqual(targetVisibility, false)
    }

    func testClosedDrawerOpensAfterThreshold() {
        let targetVisibility = AppDrawerGestureResolver.targetVisibility(
            isPresented: false,
            translation: CGSize(width: 66, height: 6),
            predictedEndTranslationWidth: 80,
            drawerWidth: 273.36
        )

        XCTAssertEqual(targetVisibility, true)
    }

    func testOpenDrawerIgnoresRightSwipeAndStaysOpenBelowCloseThreshold() {
        XCTAssertNil(
            AppDrawerGestureResolver.activeTranslation(
                isPresented: true,
                translation: CGSize(width: 48, height: 4)
            )
        )

        let targetVisibility = AppDrawerGestureResolver.targetVisibility(
            isPresented: true,
            translation: CGSize(width: -42, height: 4),
            predictedEndTranslationWidth: -54,
            drawerWidth: 320
        )

        XCTAssertEqual(targetVisibility, true)
    }

    func testOpenDrawerClosesAfterLeftSwipe() {
        let targetVisibility = AppDrawerGestureResolver.targetVisibility(
            isPresented: true,
            translation: CGSize(width: -96, height: 8),
            predictedEndTranslationWidth: -140,
            drawerWidth: 320
        )

        XCTAssertEqual(targetVisibility, false)
    }
}
