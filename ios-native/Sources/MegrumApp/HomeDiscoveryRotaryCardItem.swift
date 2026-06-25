import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeRotaryGoodsStackLayout {
    static func expandedStageWidth(_ stageWidth: CGFloat) -> CGFloat {
        stageWidth + min(28, stageWidth * 0.18)
    }

    static func heroWidth(stageWidth: CGFloat) -> CGFloat {
        min(
            max(stageWidth * 0.64, 72),
            max(72, stageWidth - 30)
        )
    }

    static func heroHeight(stageHeight: CGFloat) -> CGFloat {
        min(max(stageHeight - 12, 88), stageHeight)
    }

    static func cardMetrics(
        for position: Double,
        stageWidth: CGFloat,
        stageHeight: CGFloat
    ) -> TradeGoodsCarouselCardMetrics {
        TradeGoodsCarouselLayout.cardMetrics(
            for: position,
            heroWidth: heroWidth(stageWidth: stageWidth),
            heroHeight: heroHeight(stageHeight: stageHeight),
            stageWidth: expandedStageWidth(stageWidth)
        )
    }

    static func visibleSidePeek(stageWidth: CGFloat, stageHeight: CGFloat) -> CGFloat {
        let front = cardMetrics(for: 0, stageWidth: stageWidth, stageHeight: stageHeight)
        let side = cardMetrics(for: 1, stageWidth: stageWidth, stageHeight: stageHeight)
        return max(0, side.xOffset + side.width / 2 - front.width / 2)
    }
}

struct HomeRotaryEntry: Identifiable {
    var goods: HomeMockGoods
    var position: Double

    var id: UUID { goods.id }
}

struct HomeDiscoveryRotaryCardItem: View {
    var entry: HomeRotaryEntry
    var metrics: TradeGoodsCarouselCardMetrics
    var conditionTags: HomeConditionTagSet
    var showsConditionOverlay: Bool
    var onTap: () -> Void

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: entry.goods,
            goodsCondition: conditionTags.goods,
            exchangeCondition: conditionTags.exchange,
            paymentCondition: conditionTags.payment,
            prominence: metrics.prominence,
            showsConditionOverlay: showsConditionOverlay
        )
        .frame(width: metrics.width, height: metrics.height)
        .rotation3DEffect(
            Angle.degrees(metrics.yaw),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.72
        )
        .offset(x: metrics.xOffset, y: metrics.yOffset + 4)
        .opacity(metrics.opacity)
        .zIndex(metrics.zIndex)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .simultaneousGesture(
            TapGesture().onEnded {
                onTap()
            }
        )
        .accessibilityHidden(abs(entry.position) > 0.45)
    }
}
