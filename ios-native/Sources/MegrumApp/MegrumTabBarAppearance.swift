import CoreGraphics

#if os(iOS)
import UIKit
#endif

enum MegrumTabBarLayoutMetrics {
    static let titleVerticalAdjustment: CGFloat = -8
    static let imageVerticalInset: CGFloat = 3
    static let hidesSystemBackground = true
}

enum MegrumTabBarAppearance {
    static func configure() {
        #if os(iOS)
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.isTranslucent = true

        if #unavailable(iOS 26) {
            let appearance = UITabBarAppearance()
            if MegrumTabBarLayoutMetrics.hidesSystemBackground {
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = nil
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
            }

            tabBarAppearance.standardAppearance = appearance
            tabBarAppearance.scrollEdgeAppearance = appearance
            tabBarAppearance.backgroundImage = UIImage()
            tabBarAppearance.shadowImage = UIImage()
        } else {
            // Keep the system Liquid Glass tab bar on iOS 26 instead of forcing
            // the older transparent appearance proxy configuration.
            tabBarAppearance.backgroundImage = nil
            tabBarAppearance.shadowImage = nil
        }

        UITabBarItem.appearance().titlePositionAdjustment = UIOffset(
            horizontal: 0,
            vertical: MegrumTabBarLayoutMetrics.titleVerticalAdjustment
        )
        UITabBarItem.appearance().imageInsets = UIEdgeInsets(
            top: MegrumTabBarLayoutMetrics.imageVerticalInset,
            left: 0,
            bottom: -MegrumTabBarLayoutMetrics.imageVerticalInset,
            right: 0
        )
        #endif
    }
}
