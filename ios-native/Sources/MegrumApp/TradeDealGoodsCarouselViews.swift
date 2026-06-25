import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsCarouselColumn: View {
    var title: String
    var emptyTitle: String
    var items: [GoodsItem]
    var accentColor: Color
    var badgeTitle: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex = 0
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Text(countText)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor, in: Capsule())
            }

            if items.isEmpty {
                TradeGoodsEmptyCarouselStage(title: emptyTitle, accentColor: accentColor)
                    .frame(height: TradeGoodsCarouselLayout.stageHeight)
            } else {
                carousel
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var countText: String {
        guard !items.isEmpty else {
            return "0/0"
        }
        return "\(selectedIndex + 1)/\(items.count)"
    }

    private var tableStep: Double {
        360.0 / Double(max(items.count, 3))
    }

    private var displayedDragProgress: Double {
        reduceMotion ? 0 : dragProgress
    }

    private var carousel: some View {
        GeometryReader { proxy in
            TradeGoodsCarouselStage(
                items: items,
                selectedIndex: selectedIndex,
                dragProgress: displayedDragProgress,
                tableRotation: (Double(selectedIndex) + displayedDragProgress) * tableStep,
                accentColor: accentColor,
                badgeTitle: badgeTitle
            )
            .contentShape(Rectangle())
            .highPriorityGesture(carouselDragGesture(width: proxy.size.width))
        }
        .frame(height: TradeGoodsCarouselLayout.stageHeight)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)を横スワイプで回転")
        .accessibilityValue(countText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                settleCarousel(indexDelta: 1)
            case .decrement:
                settleCarousel(indexDelta: -1)
            @unknown default:
                break
            }
        }
        .onChange(of: items.map(\.id)) { _, _ in
            selectedIndex = min(selectedIndex, max(0, items.count - 1))
            dragProgress = 0
        }
    }

    private func carouselDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: HorizontalSwipeIntentResolver.minimumHorizontalDistance)
            .onChanged { value in
                guard items.count > 1, !reduceMotion else {
                    return
                }
                guard let progress = carouselDragProgress(translation: value.translation, width: width) else {
                    if abs(value.translation.height) > abs(value.translation.width) {
                        dragProgress = 0
                    }
                    return
                }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dragProgress = progress
                }
            }
            .onEnded { value in
                guard items.count > 1 else {
                    dragProgress = 0
                    return
                }
                guard isHorizontalCarouselDrag(value.translation) else {
                    dragProgress = 0
                    return
                }
                let denominator = max(width * 0.58, 72)
                let projectedProgress = -Double(value.predictedEndTranslation.width / denominator)
                let actualProgress = -Double(value.translation.width / denominator)
                let resolvedProgress = abs(projectedProgress) > abs(actualProgress) ? projectedProgress : actualProgress
                let indexDelta: Int
                if resolvedProgress > 0.34 {
                    indexDelta = 1
                } else if resolvedProgress < -0.34 {
                    indexDelta = -1
                } else {
                    indexDelta = 0
                }
                settleCarousel(indexDelta: indexDelta)
            }
    }

    private func carouselDragProgress(translation: CGSize, width: CGFloat) -> Double? {
        guard isHorizontalCarouselDrag(translation) else {
            return nil
        }
        let denominator = max(width * 0.58, 72)
        return max(-1.15, min(1.15, -Double(translation.width / denominator)))
    }

    private func isHorizontalCarouselDrag(_ translation: CGSize) -> Bool {
        HorizontalSwipeIntentResolver.isHorizontalSwipe(translation)
    }

    private func settleCarousel(indexDelta: Int) {
        let updates = {
            if indexDelta != 0 {
                selectedIndex = wrappedIndex(selectedIndex + indexDelta)
            }
            dragProgress = 0
        }
        guard !reduceMotion else {
            updates()
            return
        }
        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.82, blendDuration: 0.12), updates)
    }

    private func wrappedIndex(_ index: Int) -> Int {
        (index % items.count + items.count) % items.count
    }
}
