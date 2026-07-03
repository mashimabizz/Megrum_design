import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsCarouselColumn: View {
    var title: String
    var emptyTitle: String
    var items: [GoodsItem]
    var cashOffer: Bool
    var cashAmount: Int?
    var accentColor: Color
    var badgeTitle: String?
    var onStageTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentationState = TradeGoodsCarouselPresentationState()

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

            if displayItems.isEmpty {
                TradeGoodsEmptyCarouselStage(title: emptyTitle, accentColor: accentColor)
                    .frame(height: TradeGoodsCarouselLayout.stageHeight)
            } else {
                carousel
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var countText: String {
        guard !displayItems.isEmpty else {
            return "0/0"
        }
        return presentationState.countText(itemCount: displayItems.count)
    }

    private var displayItems: [TradeDealDisplayItem] {
        items.map(TradeDealDisplayItem.goods) + (cashOffer ? [.cash(amount: cashAmount)] : [])
    }

    private var carousel: some View {
        GeometryReader { proxy in
            TradeGoodsCarouselStage(
                items: items,
                displayItems: displayItems,
                selectedIndex: presentationState.selectedIndex,
                dragProgress: presentationState.displayedDragProgress(reduceMotion: reduceMotion),
                tableRotation: presentationState.tableRotation(
                    itemCount: displayItems.count,
                    reduceMotion: reduceMotion
                ),
                accentColor: accentColor,
                badgeTitle: badgeTitle
            )
            .contentShape(Rectangle())
            .modifier(TradeGoodsCarouselGestureModifier(
                width: proxy.size.width,
                usesScrollFriendlyPan: onStageTap != nil,
                isPanEnabled: displayItems.count > 1 && !reduceMotion,
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
        .onChange(of: displayItems.map(\.id)) { _, _ in
            presentationState.clampSelection(itemCount: displayItems.count)
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
        guard displayItems.count > 1, !reduceMotion else {
            return
        }
        guard let progress = TradeGoodsCarouselPresentationState.dragProgress(
            translation: translation,
            width: width
        ) else {
            if abs(translation.height) > abs(translation.width) {
                presentationState.resetDragProgress()
            }
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            presentationState.updateDragProgress(progress)
        }
    }

    private func handleCarouselDragEnded(
        translation: CGSize,
        projectedTranslationWidth: CGFloat,
        width: CGFloat
    ) {
        guard displayItems.count > 1 else {
            presentationState.resetDragProgress()
            return
        }
        guard let indexDelta = TradeGoodsCarouselPresentationState.resolvedIndexDelta(
            translation: translation,
            projectedTranslationWidth: projectedTranslationWidth,
            width: width
        ) else {
            presentationState.resetDragProgress()
            return
        }
        settleCarousel(indexDelta: indexDelta)
    }

    private func settleCarousel(indexDelta: Int) {
        let updates = {
            presentationState.settle(indexDelta: indexDelta, itemCount: displayItems.count)
        }
        guard !reduceMotion else {
            updates()
            return
        }
        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.82, blendDuration: 0.12), updates)
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
