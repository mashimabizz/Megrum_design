import CoreGraphics
import Foundation

enum TradeGoodsCarouselLayout {
    static let stageHeight: CGFloat = 166

    static func cardMetrics(
        for position: Double,
        heroWidth: CGFloat,
        heroHeight: CGFloat,
        stageWidth: CGFloat
    ) -> TradeGoodsCarouselCardMetrics {
        let clampedPosition = max(-1.18, min(1.18, position))
        let distance = min(abs(clampedPosition), 1.18)
        let prominence = max(0, 1 - min(distance, 1))
        let sideWidth = heroWidth * 0.68
        let sideHeight = heroHeight * 0.84
        let width = sideWidth + (heroWidth - sideWidth) * prominence
        let height = sideHeight + (heroHeight - sideHeight) * prominence
        let radians = clampedPosition * 54 * .pi / 180
        let maxOffsetInsideStage = max(0, (stageWidth - width) / 2 - 5)
        let orbitX = min(stageWidth * 0.26, maxOffsetInsideStage)
        let xOffset = CGFloat(sin(radians)) * orbitX
        let yOffset = -12 + CGFloat(1 - cos(radians)) * 11
        let yaw = -clampedPosition * 24
        let opacity = max(0.48, 1 - distance * 0.16)
        let zIndex = 20 - distance
        return TradeGoodsCarouselCardMetrics(
            width: width,
            height: height,
            xOffset: xOffset,
            yOffset: yOffset,
            yaw: yaw,
            opacity: opacity,
            prominence: prominence,
            zIndex: zIndex
        )
    }
}

struct TradeGoodsCarouselCardMetrics: Equatable {
    var width: CGFloat
    var height: CGFloat
    var xOffset: CGFloat
    var yOffset: CGFloat
    var yaw: Double
    var opacity: Double
    var prominence: Double
    var zIndex: Double
}
