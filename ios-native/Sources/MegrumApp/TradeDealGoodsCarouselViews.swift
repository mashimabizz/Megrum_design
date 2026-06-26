import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsCarouselColumn: View {
    var title: String
    var emptyTitle: String
    var items: [GoodsItem]
    var accentColor: Color
    var badgeTitle: String?
    var onStageTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex = 0
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Text(countText)
                    .font(.system(size: 9.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
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
            .modifier(TradeGoodsCarouselGestureModifier(
                width: proxy.size.width,
                usesScrollFriendlyPan: onStageTap != nil,
                isPanEnabled: items.count > 1 && !reduceMotion,
                onStageTap: onStageTap,
                onChanged: { translation in
                    handleCarouselDragChanged(translation: translation, width: proxy.size.width)
                },
                onEnded: { translation, projectedTranslationWidth in
                    handleCarouselDragEnded(
                        translation: translation,
                        projectedTranslationWidth: projectedTranslationWidth,
                        width: proxy.size.width
                    )
                },
                swiftUIGesture: carouselDragGesture(width: proxy.size.width)
            ))
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
                handleCarouselDragChanged(translation: value.translation, width: width)
            }
            .onEnded { value in
                handleCarouselDragEnded(
                    translation: value.translation,
                    projectedTranslationWidth: value.predictedEndTranslation.width,
                    width: width
                )
            }
    }

    private func handleCarouselDragChanged(translation: CGSize, width: CGFloat) {
        guard items.count > 1, !reduceMotion else {
            return
        }
        guard let progress = carouselDragProgress(translation: translation, width: width) else {
            if abs(translation.height) > abs(translation.width) {
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

    private func handleCarouselDragEnded(
        translation: CGSize,
        projectedTranslationWidth: CGFloat,
        width: CGFloat
    ) {
        guard items.count > 1 else {
            dragProgress = 0
            return
        }
        guard isHorizontalCarouselDrag(translation) else {
            dragProgress = 0
            return
        }
        let denominator = max(width * 0.58, 72)
        let projectedProgress = -Double(projectedTranslationWidth / denominator)
        let actualProgress = -Double(translation.width / denominator)
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

private struct TradeGoodsCarouselGestureModifier<SwiftUIGesture: Gesture>: ViewModifier {
    var width: CGFloat
    var usesScrollFriendlyPan: Bool
    var isPanEnabled: Bool
    var onStageTap: (() -> Void)?
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void
    var swiftUIGesture: SwiftUIGesture

    func body(content: Content) -> some View {
        if usesScrollFriendlyPan {
#if canImport(UIKit)
            content.overlay {
                ScrollFriendlyHorizontalPanView(
                    isPanEnabled: isPanEnabled,
                    onTap: { _ in
                        onStageTap?()
                    },
                    onChanged: onChanged,
                    onEnded: onEnded
                )
            }
#else
            content.simultaneousGesture(swiftUIGesture)
#endif
        } else {
            content.simultaneousGesture(swiftUIGesture)
        }
    }
}
