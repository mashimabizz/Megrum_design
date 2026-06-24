import SwiftUI

enum AppDrawerDestination: String, Identifiable {
    case profile
    case notifications
    case profileEdit
    case oshiSettings
    case schedules
    case paymentSettings
    case exchangeSettings
    case settings
    case help

    var id: String { rawValue }

    static let primaryItems: [AppDrawerDestination] = [
        .profile,
        .notifications,
        .oshiSettings,
        .schedules,
        .paymentSettings,
        .exchangeSettings
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
            "支払条件設定"
        case .exchangeSettings:
            "交換条件設定"
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
        case .settings:
            "checkmark.shield"
        case .help:
            "doc.text"
        }
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
    static let closedHomeContentGestureTopInset: CGFloat = 92
    static let closedHomeContentGestureBottomInset: CGFloat = 116
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
    private static let homeDiscoveryContentTopPadding: CGFloat = 72
    private static let homeDiscoveryFirstGridRows = 2
    private static let homeDiscoverySecondSectionTop: CGFloat = 466
    private static let homeDiscoverySecondGridRows = 5
    private static let homeDiscoveryHorizontalPadding: CGFloat = 20
    private static let homeDiscoveryColumnSpacing: CGFloat = 22
    private static let homeDiscoveryGridHeaderHeight: CGFloat = 18
    private static let homeDiscoveryGridSpacing: CGFloat = 8
    private static let homeDiscoveryCardHeight: CGFloat = 170
    private static let homeDiscoveryGridRowSpacing: CGFloat = 14
    private static let homeDiscoveryCardImageTopInset: CGFloat = 26
    private static let homeDiscoveryCardImageHeight: CGFloat = 132

    static func isHomeContentSwipeStartAllowed(startLocation: CGPoint, screenSize: CGSize) -> Bool {
        guard screenSize.height > 0 else {
            return true
        }
        let topBoundary = AppDrawerVisualMetrics.closedHomeContentGestureTopInset
        let bottomBoundary = max(topBoundary, screenSize.height - AppDrawerVisualMetrics.closedHomeContentGestureBottomInset)
        guard startLocation.y >= topBoundary && startLocation.y <= bottomBoundary else {
            return false
        }
        return !isHomeGoodsCardStart(startLocation: startLocation, screenWidth: screenSize.width)
    }

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
            && isHomeContentSwipeStartAllowed(startLocation: startLocation, screenSize: screenSize)
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

    private static func isHomeGoodsCardStart(startLocation: CGPoint, screenWidth: CGFloat) -> Bool {
        guard isInsideHomeCandidateColumn(startX: startLocation.x, screenWidth: screenWidth) else {
            return false
        }
        return isInsideHomeGridImageRows(
            startY: startLocation.y,
            sectionTop: homeDiscoveryContentTopPadding,
            rowCount: homeDiscoveryFirstGridRows
        ) || isInsideHomeGridImageRows(
            startY: startLocation.y,
            sectionTop: homeDiscoverySecondSectionTop,
            rowCount: homeDiscoverySecondGridRows
        )
    }

    private static func isInsideHomeCandidateColumn(startX: CGFloat, screenWidth: CGFloat) -> Bool {
        let columnWidth = max(
            0,
            (screenWidth - homeDiscoveryHorizontalPadding * 2 - homeDiscoveryColumnSpacing) / 2
        )
        let leftColumn = homeDiscoveryHorizontalPadding...(homeDiscoveryHorizontalPadding + columnWidth)
        let rightColumnStart = homeDiscoveryHorizontalPadding + columnWidth + homeDiscoveryColumnSpacing
        let rightColumn = rightColumnStart...(rightColumnStart + columnWidth)
        return leftColumn.contains(startX) || rightColumn.contains(startX)
    }

    private static func isInsideHomeGridImageRows(startY: CGFloat, sectionTop: CGFloat, rowCount: Int) -> Bool {
        let firstRowTop = sectionTop + homeDiscoveryGridHeaderHeight + homeDiscoveryGridSpacing

        for rowIndex in 0..<rowCount {
            let rowTop = firstRowTop + CGFloat(rowIndex) * (
                homeDiscoveryCardHeight + homeDiscoveryGridRowSpacing
            )
            let imageRange = (rowTop + homeDiscoveryCardImageTopInset)...(
                rowTop + homeDiscoveryCardImageTopInset + homeDiscoveryCardImageHeight
            )
            if imageRange.contains(startY) {
                return true
            }
        }
        return false
    }

    private static func isHorizontalSwipe(_ translation: CGSize, isPresented: Bool) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        let minimumDistance = isPresented ? openStartMinimumDistance : closedStartMinimumDistance
        let dominance = isPresented ? openHorizontalDominance : closedHorizontalDominance
        return absX > minimumDistance && absX > absY * dominance
    }
}
