import SwiftUI

struct HomeDiscoveryRotaryCardStage: View {
    var entries: [HomeRotaryEntry]
    var showsConditionOverlay: Bool
    var conditionTags: (HomeMockGoods) -> HomeConditionTagSet
    var onTapPosition: (Double) -> Void
    var isDragEnabled: Bool
    var onDragChanged: (CGSize, CGFloat) -> Void
    var onDragEnded: (CGSize, CGFloat, CGFloat) -> Void

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
            .modifier(HomeDiscoveryRotaryCardStageGestureModifier(
                isPanEnabled: isDragEnabled,
                onTap: { location in
                    handleTap(at: location, stageSize: proxy.size)
                },
                onChanged: { translation in
                    onDragChanged(translation, proxy.size.width)
                },
                onEnded: { translation, projectedTranslationWidth in
                    onDragEnded(translation, projectedTranslationWidth, proxy.size.width)
                },
                swiftUIGesture: dragGesture(width: proxy.size.width)
            ))
        }
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: HorizontalSwipeIntentResolver.minimumHorizontalDistance)
            .onChanged { value in
                onDragChanged(value.translation, width)
            }
            .onEnded { value in
                onDragEnded(value.translation, value.predictedEndTranslation.width, width)
            }
    }

    private func handleTap(at location: CGPoint, stageSize: CGSize) {
        guard let tappedEntry = tappedEntry(at: location, stageSize: stageSize) else {
            return
        }
        onTapPosition(tappedEntry.position)
    }

    private func tappedEntry(at location: CGPoint, stageSize: CGSize) -> HomeRotaryEntry? {
        entries
            .compactMap { entry -> (entry: HomeRotaryEntry, zIndex: Double)? in
                let metrics = HomeRotaryGoodsStackLayout.cardMetrics(
                    for: entry.position,
                    stageWidth: stageSize.width,
                    stageHeight: stageSize.height
                )
                let cardCenter = CGPoint(
                    x: stageSize.width / 2 + metrics.xOffset,
                    y: stageSize.height / 2 + metrics.yOffset + 4
                )
                let cardRect = CGRect(
                    x: cardCenter.x - metrics.width / 2,
                    y: cardCenter.y - metrics.height / 2,
                    width: metrics.width,
                    height: metrics.height
                )
                guard cardRect.contains(location) else {
                    return nil
                }
                return (entry, metrics.zIndex)
            }
            .max { lhs, rhs in lhs.zIndex < rhs.zIndex }?
            .entry
    }
}

private struct HomeDiscoveryRotaryCardStageGestureModifier<SwiftUIGesture: Gesture>: ViewModifier {
    var isPanEnabled: Bool
    var onTap: (CGPoint) -> Void
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void
    var swiftUIGesture: SwiftUIGesture

    func body(content: Content) -> some View {
#if canImport(UIKit)
        content.overlay {
            ScrollFriendlyHorizontalPanView(
                isPanEnabled: isPanEnabled,
                onTap: onTap,
                onChanged: onChanged,
                onEnded: onEnded
            )
        }
#else
        content.simultaneousGesture(swiftUIGesture)
#endif
    }
}
