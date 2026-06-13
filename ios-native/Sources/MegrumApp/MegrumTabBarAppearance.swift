import CoreGraphics

#if os(iOS)
import UIKit
#endif

enum MegrumTabBarLayoutMetrics {
    static let titleVerticalAdjustment: CGFloat = -4
    static let hidesSystemBackground = true
}

enum MegrumTabBarAppearance {
    static func configure() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        if MegrumTabBarLayoutMetrics.hidesSystemBackground {
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = nil
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
        }

        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.standardAppearance = appearance
        tabBarAppearance.scrollEdgeAppearance = appearance
        tabBarAppearance.isTranslucent = true
        tabBarAppearance.backgroundImage = UIImage()
        tabBarAppearance.shadowImage = UIImage()

        UITabBarItem.appearance().titlePositionAdjustment = UIOffset(
            horizontal: 0,
            vertical: MegrumTabBarLayoutMetrics.titleVerticalAdjustment
        )
        #endif
    }
}
