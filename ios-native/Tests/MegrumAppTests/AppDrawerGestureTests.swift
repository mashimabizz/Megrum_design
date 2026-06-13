@testable import MegrumApp
import XCTest

final class AppDrawerGestureTests: XCTestCase {
    func testDrawerItemsMatchRnProfileDrawerOrder() {
        XCTAssertEqual(
            AppDrawerDestination.primaryItems.map(\.title),
            [
                "プロフィール",
                "通知",
                "推し設定",
                "スケジュール",
                "完了した取引"
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

    func testDrawerVisualMetricsMatchRnXStyleForegroundPush() {
        XCTAssertEqual(AppDrawerVisualMetrics.minimumDrawerWidth, 320)
        XCTAssertEqual(AppDrawerVisualMetrics.maximumDrawerWidth, 380)
        XCTAssertEqual(AppDrawerVisualMetrics.drawerWidthRatio, 0.9)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundOpenRatio, 0.68)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundOpenInset, 34)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundCornerRadius, 18)
        XCTAssertEqual(AppDrawerVisualMetrics.whiteoutOpacity, 0.18)
        XCTAssertEqual(AppDrawerVisualMetrics.foregroundShadowOpacity, 0.16)
        XCTAssertEqual(AppDrawerVisualMetrics.drawerParallax, -12)
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
    }

    func testClosedDrawerStartsTrackingOnHorizontalRightSwipe() {
        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: false,
            translation: CGSize(width: 6, height: 1)
        )

        XCTAssertEqual(translation, 6)
    }

    func testClosedDrawerDoesNotRequireLeadingEdgeOrigin() {
        let translation = AppDrawerGestureResolver.activeTranslation(
            isPresented: false,
            translation: CGSize(width: 54, height: 6)
        )

        XCTAssertEqual(translation, 54)
    }

    func testDrawerGestureThresholdsMatchRnPanResponderModel() {
        XCTAssertEqual(AppDrawerGestureResolver.closedStartMinimumDistance, 5)
        XCTAssertEqual(AppDrawerGestureResolver.openStartMinimumDistance, 6)
        XCTAssertEqual(AppDrawerGestureResolver.closedHorizontalDominance, 1)
        XCTAssertEqual(AppDrawerGestureResolver.openHorizontalDominance, 1)
        XCTAssertEqual(AppDrawerGestureResolver.openThresholdRatio, 0.24)
        XCTAssertEqual(AppDrawerGestureResolver.predictedMomentumBonus, 32)
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
