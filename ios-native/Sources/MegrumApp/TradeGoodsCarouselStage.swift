import MegrumCore
import SwiftUI

struct TradeGoodsCarouselStage: View {
    var items: [GoodsItem]
    var displayItems: [TradeDealDisplayItem]
    var selectedIndex: Int
    var dragProgress: Double
    var tableRotation: Double
    var accentColor: Color
    var badgeTitle: String?

    var body: some View {
        GeometryReader { proxy in
            let heroWidth = min(max(proxy.size.width * 0.48, 50), 64)
            let heroHeight = min(proxy.size.height - 22, 88)
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.24), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 4,
                            endRadius: heroWidth * 0.72
                        )
                    )
                    .frame(width: min(proxy.size.width * 0.72, 88), height: 18)
                    .offset(y: heroHeight * 0.43)
                    .accessibilityHidden(true)

                TradeRotatingGoodsTable(accentColor: accentColor, rotation: tableRotation)
                    .frame(width: min(proxy.size.width * 0.76, 96), height: 34)
                    .offset(y: heroHeight * 0.43)
                    .zIndex(0)

                ForEach(visibleEntries) { entry in
                    let metrics = TradeGoodsCarouselLayout.cardMetrics(
                        for: entry.position,
                        heroWidth: heroWidth,
                        heroHeight: heroHeight,
                        stageWidth: proxy.size.width
                    )
                    TradeGoodsOrbitCard(
                        item: entry.item,
                        accentColor: accentColor,
                        prominence: metrics.prominence,
                        badgeTitle: badgeTitle
                    )
                    .frame(width: metrics.width, height: metrics.height)
                    .rotation3DEffect(
                        Angle.degrees(metrics.yaw),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.72
                    )
                    .offset(x: metrics.xOffset, y: metrics.yOffset)
                    .opacity(metrics.opacity)
                    .zIndex(metrics.zIndex)
                    .accessibilityHidden(abs(entry.position) > 0.45)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityHidden(true)
    }

    private var visibleEntries: [TradeGoodsCarouselEntry] {
        displayItems.indices
            .map { index in
                TradeGoodsCarouselEntry(
                    item: displayItems[index],
                    position: relativePosition(for: index)
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.position) == abs(rhs.position) {
                    return lhs.position < rhs.position
                }
                return abs(lhs.position) < abs(rhs.position)
            }
            .prefix(3)
            .sorted { lhs, rhs in
                lhs.position < rhs.position
            }
    }

    private func relativePosition(for index: Int) -> Double {
        guard !displayItems.isEmpty else {
            return 0
        }
        let count = displayItems.count
        let forward = (index - selectedIndex + count) % count
        let backward = (selectedIndex - index + count) % count
        let shortest = forward <= backward ? Double(forward) : -Double(backward)
        return shortest - dragProgress
    }
}

private struct TradeGoodsCarouselEntry: Identifiable {
    var item: TradeDealDisplayItem
    var position: Double

    var id: String {
        item.id
    }
}
