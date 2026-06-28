import Foundation
import MegrumCore
import SwiftUI

enum AppDrawerDestination: String, Identifiable {
    case profile
    case notifications
    case profileEdit
    case oshiSettings
    case schedules
    case paymentSettings
    case exchangeSettings
    case megrumPlus
    case settings
    case help

    var id: String { rawValue }

    static let primaryItems: [AppDrawerDestination] = [
        .profile,
        .notifications,
        .oshiSettings,
        .paymentSettings,
        .exchangeSettings
    ]

    static let plusItems: [AppDrawerDestination] = [
        .megrumPlus
    ]

    static let compactItems: [AppDrawerDestination] = [
        .settings,
        .help
    ]

    var title: String {
        switch self {
        case .profile:
            "プロフィール"
        case .notifications:
            "通知"
        case .profileEdit:
            "プロフィール編集"
        case .oshiSettings:
            "推し設定"
        case .schedules:
            "スケジュール"
        case .paymentSettings:
            "支払い方法の設定"
        case .exchangeSettings:
            "交換条件の設定"
        case .megrumPlus:
            "Megrum プレミアム"
        case .settings:
            "設定とプライバシー"
        case .help:
            "ヘルプ"
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "star"
        case .notifications:
            "bell"
        case .profileEdit:
            "square.and.pencil"
        case .oshiSettings:
            "sparkles"
        case .schedules:
            "calendar"
        case .paymentSettings:
            "yensign.circle"
        case .exchangeSettings:
            "arrow.left.arrow.right.circle"
        case .megrumPlus:
            "sparkles.rectangle.stack"
        case .settings:
            "checkmark.shield"
        case .help:
            "doc.text"
        }
    }
}

enum AppDrawerSettingsBadgePolicy {
    static let needsConfigurationBadge = "要設定"

    static func exchangeBadgeText(
        settings: HomeDefaultExchangeSettings,
        isExplicitlyConfigured: Bool,
        now: Date = Date()
    ) -> String? {
        settings.needsConfiguration(isExplicitlyConfigured: isExplicitlyConfigured, now: now)
            ? needsConfigurationBadge
            : nil
    }

    static func paymentBadgeText(methods: [UserPaymentMethod]) -> String? {
        UserPaymentMethod.normalized(methods).isEmpty ? needsConfigurationBadge : nil
    }
}

enum AppDrawerVisualMetrics {
    static let minimumDrawerWidth: CGFloat = 320
    static let maximumDrawerWidth: CGFloat = 380
    static let drawerWidthRatio: CGFloat = 0.9
    static let foregroundOpenRatio: CGFloat = 0.68
    static let foregroundOpenInset: CGFloat = 34
    static let foregroundCornerRadius: CGFloat = 18
    static let whiteoutOpacity: CGFloat = 0.18
    static let foregroundShadowOpacity: CGFloat = 0.16
    static let foregroundShadowRadius: CGFloat = 18
    static let closedEdgeGestureWidth: CGFloat = 28
    static let foregroundZIndex: Double = 1
    static let closedEdgeGestureZIndex: Double = 8
    static let drawerZIndex: Double = 10

    static func drawerWidth(screenWidth: CGFloat) -> CGFloat {
        min(maximumDrawerWidth, max(minimumDrawerWidth, screenWidth * drawerWidthRatio))
    }

    static func openOffset(screenWidth: CGFloat) -> CGFloat {
        let width = drawerWidth(screenWidth: screenWidth)
        return min(width - foregroundOpenInset, screenWidth * foregroundOpenRatio)
    }

    static func drawerOffset(drawerWidth: CGFloat, progress: CGFloat) -> CGFloat {
        -drawerWidth * (1 - clampedProgress(progress))
    }

    static func presentationProgress(
        isPresented: Bool,
        dragTranslation: CGFloat,
        drawerTravel: CGFloat
    ) -> CGFloat {
        guard drawerTravel > 0 else {
            return isPresented ? 1 : 0
        }
        let baseOffset = isPresented ? drawerTravel : 0
        let gestureOffset = isPresented ? min(0, dragTranslation) : max(0, dragTranslation)
        let revealed = min(drawerTravel, max(0, baseOffset + gestureOffset))
        return revealed / drawerTravel
    }

    static func clampedProgress(_ progress: CGFloat) -> CGFloat {
        min(1, max(0, progress))
    }
}

enum AppDrawerGestureResolver {
    static let closedStartMinimumDistance: CGFloat = 5
    static let openStartMinimumDistance: CGFloat = 6
    static let closedHorizontalDominance: CGFloat = 1
    static let openHorizontalDominance: CGFloat = 1
    static let openThresholdRatio: CGFloat = 0.24
    static let predictedMomentumBonus: CGFloat = 32
    static let drawerItemTapSuppressionDistance: CGFloat = 8
    static let drawerItemTapSuppressionDuration: Double = 0.28

    static func isClosedHomeDrawerSwipeStartAllowed(
        isHomeTabSelected: Bool,
        isDrawerPresented: Bool,
        isSearchPresented: Bool,
        startLocation: CGPoint,
        screenSize: CGSize
    ) -> Bool {
        isHomeTabSelected
            && !isDrawerPresented
            && !isSearchPresented
            && isClosedEdgeSwipeStartAllowed(startLocation: startLocation, screenSize: screenSize)
    }

    static func isClosedEdgeSwipeStartAllowed(startLocation: CGPoint, screenSize: CGSize) -> Bool {
        guard screenSize.width > 0, screenSize.height > 0 else {
            return false
        }
        guard CGRect(origin: .zero, size: screenSize).contains(startLocation) else {
            return false
        }
        return startLocation.x <= AppDrawerVisualMetrics.closedEdgeGestureWidth
    }

    static func isOpenDrawerSwipeStartAllowed(startLocation: CGPoint, screenSize: CGSize) -> Bool {
        guard screenSize.width > 0, screenSize.height > 0 else {
            return false
        }
        return CGRect(origin: .zero, size: screenSize).contains(startLocation)
    }

    static func activeTranslation(isPresented: Bool, translation: CGSize) -> CGFloat? {
        guard isHorizontalSwipe(translation, isPresented: isPresented) else {
            return nil
        }
        if isPresented {
            guard translation.width < 0 else {
                return nil
            }
            return translation.width
        }

        guard translation.width > 0 else {
            return nil
        }
        return translation.width
    }

    static func shouldSuppressDrawerItemTap(translation: CGSize) -> Bool {
        max(abs(translation.width), abs(translation.height)) >= drawerItemTapSuppressionDistance
    }

    static func targetVisibility(
        isPresented: Bool,
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        drawerWidth: CGFloat
    ) -> Bool? {
        guard isHorizontalSwipe(translation, isPresented: isPresented) else {
            return nil
        }

        let absX = abs(translation.width)
        let threshold = drawerWidth * openThresholdRatio
        let fastEnough = abs(predictedEndTranslationWidth) >= absX + predictedMomentumBonus

        if isPresented {
            let shouldClose = translation.width <= -threshold || (translation.width < 0 && fastEnough)
            return !shouldClose
        }

        let shouldOpen = translation.width >= threshold || (translation.width > 0 && fastEnough)
        return shouldOpen
    }

    private static func isHorizontalSwipe(_ translation: CGSize, isPresented: Bool) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        let minimumDistance = isPresented ? openStartMinimumDistance : closedStartMinimumDistance
        let dominance = isPresented ? openHorizontalDominance : closedHorizontalDominance
        return absX > minimumDistance && absX > absY * dominance
    }
}
