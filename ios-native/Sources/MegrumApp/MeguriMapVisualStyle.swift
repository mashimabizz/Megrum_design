import MapKit
import MegrumDesign
import SwiftUI

enum MeguriMapVisualStyle {
    static var quietStandard: MapStyle {
        .standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll
        )
    }
}

struct MeguriMapBrandToneOverlay: View {
    var topWhiteOpacity = 0.78
    var middleWhiteOpacity = 0.26
    var bottomWhiteOpacity = 0.04

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MegrumTheme.lavender.opacity(0.13),
                    MegrumTheme.sky.opacity(0.07),
                    MegrumTheme.pink.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)

            MegrumTheme.lavender.opacity(0.035)

            LinearGradient(
                colors: [
                    .white.opacity(topWhiteOpacity),
                    .white.opacity(middleWhiteOpacity),
                    .white.opacity(bottomWhiteOpacity),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
