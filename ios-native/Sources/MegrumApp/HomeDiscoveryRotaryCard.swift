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
    @State private var presentationState = HomeDiscoveryRotaryCardPresentationState()

    var body: some View {
        HomeDiscoveryRotaryCardStage(
            entries: visibleEntries,
            showsConditionOverlay: showsConditionOverlay,
            conditionTags: { conditionTags(for: $0) },
            onTapPosition: { handleTap(position: $0) },
            isDragEnabled: goods.count > 1 && !reduceMotion,
            onDragChanged: handleDragChanged,
            onDragEnded: handleDragEnded
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(selectedGoods?.title ?? "グッズ")の詳細を見る")
        .accessibilityValue(countText)
        .accessibilityHint("タップで詳細を開きます。横スワイプで画像を切り替えます。")
        .accessibilityAction {
            if let selectedGoods {
                MegrumHaptics.buttonTap()
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
            presentationState.clampSelection(itemCount: goods.count)
            notifySelection()
        }
        .onChange(of: presentationState.selectedIndex) { _, _ in
            notifySelection()
        }
        .onAppear {
            notifySelection()
        }
    }

    private var selectedGoods: HomeMockGoods? {
        guard goods.indices.contains(presentationState.selectedIndex) else {
            return nil
        }
        return goods[presentationState.selectedIndex]
    }

    private func conditionTags(for goods: HomeMockGoods) -> HomeConditionTagSet {
        conditionTagsForGoods?(goods) ?? HomeConditionTagSet(
            goods: goodsCondition,
            exchange: exchangeCondition,
            payment: paymentCondition
        )
    }

    private var countText: String {
        guard !goods.isEmpty else {
            return "0/0"
        }
        return presentationState.countText(itemCount: goods.count)
    }

    private var visibleEntries: [HomeRotaryEntry] {
        // 表示する3枚を中心に近い順で選ぶが、宣言順は index 固定にする。
        // 位置順で並べ替えると回転アニメ中に ZStack の宣言順が入れ替わり、奥のカードが
        // 一瞬手前に描画される（貫通して見える）。宣言順を安定させ zIndex だけで前後を決める。iter1226.379。
        goods.indices
            .map { index in
                (index: index, entry: HomeRotaryEntry(goods: goods[index], position: relativePosition(for: index)))
            }
            .sorted { lhs, rhs in
                if abs(lhs.entry.position) == abs(rhs.entry.position) {
                    return lhs.entry.position < rhs.entry.position
                }
                return abs(lhs.entry.position) < abs(rhs.entry.position)
            }
            .prefix(3)
            .sorted { $0.index < $1.index }
            .map(\.entry)
    }

    private func relativePosition(for index: Int) -> Double {
        presentationState.relativePosition(
            for: index,
            itemCount: goods.count,
            reduceMotion: reduceMotion
        )
    }

    private func handleDragChanged(translation: CGSize, width: CGFloat) {
        guard goods.count > 1, !reduceMotion else {
            return
        }
        guard let progress = HomeDiscoveryRotaryCardPresentationState.dragProgress(
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

    private func handleDragEnded(
        translation: CGSize,
        projectedTranslationWidth: CGFloat,
        width: CGFloat
    ) {
        guard goods.count > 1 else {
            presentationState.resetDragProgress()
            return
        }
        guard let delta = HomeDiscoveryRotaryCardPresentationState.resolvedIndexDelta(
            translation: translation,
            projectedTranslationWidth: projectedTranslationWidth,
            width: width
        ) else {
            presentationState.resetDragProgress()
            return
        }
        settleCarousel(indexDelta: delta)
    }

    private func handleTap(position: Double) {
        if abs(position) <= 0.45 {
            if let selectedGoods {
                MegrumHaptics.buttonTap()
                onActivate?(selectedGoods)
            }
            return
        }
        settleCarousel(indexDelta: position > 0 ? 1 : -1)
    }

    private func settleCarousel(indexDelta: Int) {
        let updates = {
            presentationState.settle(indexDelta: indexDelta, itemCount: goods.count)
        }

        guard !reduceMotion else {
            updates()
            return
        }

        withAnimation(.interactiveSpring(response: 0.46, dampingFraction: 0.82, blendDuration: 0.12), updates)
    }

    private func notifySelection() {
        if let selectedGoods {
            onSelectionChange?(selectedGoods)
        }
    }
}
