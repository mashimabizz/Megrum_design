import SwiftUI

struct HomeDiscoveryRotaryCardStage: View {
    var entries: [HomeRotaryEntry]
    var showsConditionOverlay: Bool
    var conditionTags: (HomeMockGoods) -> HomeConditionTagSet
    var onTapPosition: (Double) -> Void
    var onDragChanged: (DragGesture.Value, CGFloat) -> Void
    var onDragEnded: (DragGesture.Value, CGFloat) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(entries) { entry in
                    let metrics = HomeRotaryGoodsStackLayout.cardMetrics(
                        for: entry.position,
                        stageWidth: proxy.size.width,
                        stageHeight: proxy.size.height
                    )
                    HomeDiscoveryRotaryCardItem(
                        entry: entry,
                        metrics: metrics,
                        conditionTags: conditionTags(entry.goods),
                        showsConditionOverlay: showsConditionOverlay
                    ) {
                        onTapPosition(entry.position)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(width: proxy.size.width))
        }
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: HorizontalSwipeIntentResolver.minimumHorizontalDistance)
            .onChanged { value in
                onDragChanged(value, width)
            }
            .onEnded { value in
                onDragEnded(value, width)
            }
    }
}
