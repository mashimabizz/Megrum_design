import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryRotaryCard: View {
    var goods: [HomeMockGoods]
    var goodsCondition: HomeGoodsCondition
    var exchangeCondition: HomeExchangeCondition
    var paymentCondition: HomePaymentCondition
    var conditionTagsForGoods: ((HomeMockGoods) -> HomeConditionTagSet)? = nil
    var showsConditionOverlay = true
    var onSelectionChange: ((HomeMockGoods) -> Void)? = nil
    var onActivate: ((HomeMockGoods) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIndex = 0
    @State private var dragProgress: Double = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(visibleEntries) { entry in
                    let metrics = HomeRotaryGoodsStackLayout.cardMetrics(
                        for: entry.position,
                        stageWidth: proxy.size.width,
                        stageHeight: proxy.size.height
                    )
                    HomeDiscoveryRotaryCardItem(
                        entry: entry,
                        metrics: metrics,
                        conditionTags: conditionTags(for: entry.goods),
                        showsConditionOverlay: showsConditionOverlay
                    ) {
                        handleTap(position: entry.position)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(width: proxy.size.width))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(selectedGoods?.title ?? "グッズ")の詳細を見る")
        .accessibilityValue(countText)
        .accessibilityHint("タップで詳細を開きます。横スワイプで画像を切り替えます。")
        .accessibilityAction {
            if let selectedGoods {
                onActivate?(selectedGoods)
            }
        }
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
        .onChange(of: goods.map(\.id)) { _, _ in
            selectedIndex = min(selectedIndex, max(0, goods.count - 1))
            dragProgress = 0
            notifySelection()
        }
        .onChange(of: selectedIndex) { _, _ in
            notifySelection()
        }
        .onAppear {
            notifySelection()
        }
    }

    private var selectedGoods: HomeMockGoods? {
        guard goods.indices.contains(selectedIndex) else {
            return nil
        }
        return goods[selectedIndex]
    }

    private func conditionTags(for goods: HomeMockGoods) -> HomeConditionTagSet {
        conditionTagsForGoods?(goods) ?? HomeConditionTagSet(
            goods: goodsCondition,
            exchange: exchangeCondition,
            payment: paymentCondition
        )
    }

    private var displayedDragProgress: Double {
        reduceMotion ? 0 : dragProgress
    }

    private var countText: String {
        guard !goods.isEmpty else {
            return "0/0"
        }
        return "\(selectedIndex + 1)/\(goods.count)"
    }

    private var visibleEntries: [HomeRotaryEntry] {
        goods.indices
            .map { index in
                HomeRotaryEntry(goods: goods[index], position: relativePosition(for: index))
            }
            .sorted { lhs, rhs in
                if abs(lhs.position) == abs(rhs.position) {
                    return lhs.position < rhs.position
                }
                return abs(lhs.position) < abs(rhs.position)
            }
            .prefix(3)
            .sorted { $0.position < $1.position }
    }

    private func relativePosition(for index: Int) -> Double {
        guard !goods.isEmpty else {
            return 0
        }
        let count = goods.count
        let forward = (index - selectedIndex + count) % count
        let backward = (selectedIndex - index + count) % count
        let shortest = forward <= backward ? Double(forward) : -Double(backward)
        return shortest - displayedDragProgress
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: HorizontalSwipeIntentResolver.minimumHorizontalDistance)
            .onChanged { value in
                guard goods.count > 1, !reduceMotion else {
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
                guard goods.count > 1 else {
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
                let progress = abs(projectedProgress) > abs(actualProgress) ? projectedProgress : actualProgress
                let delta: Int
                if progress > 0.34 {
                    delta = 1
                } else if progress < -0.34 {
                    delta = -1
                } else {
                    delta = 0
                }
                settleCarousel(indexDelta: delta)
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

    private func handleTap(position: Double) {
        if abs(position) <= 0.45 {
            if let selectedGoods {
                onActivate?(selectedGoods)
            }
            return
        }
        settleCarousel(indexDelta: position > 0 ? 1 : -1)
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
        (index % goods.count + goods.count) % goods.count
    }

    private func notifySelection() {
        if let selectedGoods {
            onSelectionChange?(selectedGoods)
        }
    }
}
