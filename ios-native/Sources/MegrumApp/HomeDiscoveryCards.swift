import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryViewerAvatar: View {
    var viewer: UserProfile?

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if let avatarURL = viewer?.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackInitial
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackInitial
                }
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 1.4)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 10, y: 5)
    }

    private var fallbackInitial: some View {
        Text(initial)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
    }

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }
}

enum HomeDiscoverySectionLayout {
    case grid
    case rail
}

struct HomeDiscoverySection: View {
    var title: String
    var candidates: [HomeDiscoveryCandidate]
    var layout: HomeDiscoverySectionLayout
    var cardTitleStyle: HomeDiscoveryCardTitleStyle = .plain
    var showsGridHeaderTitle = true
    var showsSeeAllButton = true
    var onSelect: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: layout == .grid ? 8 : 10) {
            HomeDiscoverySectionHeader(
                title: title,
                layout: layout,
                showsGridHeaderTitle: showsGridHeaderTitle,
                showsSeeAllButton: showsSeeAllButton,
                isSeeAllDisabled: candidates.isEmpty,
                onSeeAll: openFirstCandidate
            )

            switch layout {
            case .grid:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22)], spacing: 14) {
                    ForEach(candidates) { candidate in
                        HomeDiscoveryCandidateButton(
                            candidate: candidate,
                            titleStyle: cardTitleStyle,
                            cardHeight: 170,
                            onSelect: onSelect
                        )
                    }
                }
            case .rail:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(candidates) { candidate in
                            HomeHavesCandidateButton(
                                candidate: candidate,
                                onSelect: onSelect
                            )
                            .frame(width: 94)
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
        }
    }

    private func openFirstCandidate() {
        if let firstCandidate = candidates.first {
            onSelect(firstCandidate.sheet)
        }
    }
}

private struct HomeDiscoverySectionHeader: View {
    var title: String
    var layout: HomeDiscoverySectionLayout
    var showsGridHeaderTitle: Bool
    var showsSeeAllButton: Bool
    var isSeeAllDisabled: Bool
    var onSeeAll: () -> Void

    var body: some View {
        HStack {
            if layout == .rail || showsGridHeaderTitle {
                Text(title)
                    .font(.system(size: layout == .rail ? 20 : 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer()

            if showsSeeAllButton {
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("すべて見る")
                            .font(.system(size: 14, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .black))
                }
                .foregroundStyle(MegrumTheme.lavender)
            }
            .buttonStyle(.plain)
                .disabled(isSeeAllDisabled)
            }
        }
        .frame(minHeight: layout == .grid ? 18 : 24)
    }
}

private struct HomeHavesCandidateButton: View {
    var candidate: HomeDiscoveryCandidate
    var onSelect: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(spacing: 7) {
            if let goods = candidate.goods.first {
                let conditionTags = candidate.conditionTags(for: goods)
                HomeDiscoveryGoodsCard(
                    goods: goods,
                    goodsCondition: conditionTags.goods,
                    exchangeCondition: conditionTags.exchange,
                    paymentCondition: conditionTags.payment,
                    prominence: 1,
                    showsConditionOverlay: false
                )
                .frame(width: 86, height: 104)
            }

            Text(countText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(candidate.sheet())
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(candidate.title)の詳細を見る")
        .accessibilityValue("欲しがられている候補 \(countText)")
        .accessibilityHint("タップでこのグッズを欲しがっている候補を見ます。")
    }

    private var countText: String {
        "\(candidate.linkedCount)件"
    }
}

private struct HomeDiscoveryCandidateButton: View {
    var candidate: HomeDiscoveryCandidate
    var titleStyle: HomeDiscoveryCardTitleStyle
    var cardHeight: CGFloat
    var onSelect: (HomeDiscoverySheet) -> Void

    @State private var selectedGoods: HomeMockGoods?

    var body: some View {
        VStack(spacing: 0) {
            Text(cardTitle)
                .font(.system(size: 14.5, weight: .heavy))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture {
                    openSelectedSheet()
                }
                .padding(.bottom, 10)

            HomeDiscoveryRotaryCard(
                goods: candidate.goods,
                goodsCondition: candidate.goodsCondition,
                exchangeCondition: candidate.exchangeCondition,
                paymentCondition: candidate.paymentCondition,
                conditionTagsForGoods: { goods in
                    candidate.conditionTags(for: goods)
                },
                showsConditionOverlay: false,
                onSelectionChange: { goods in
                    selectedGoods = goods
                },
                onActivate: { goods in
                    onSelect(candidate.sheet(selectedGoods: goods))
                }
            )
            .frame(height: max(118, cardHeight - 42))

            HomeDiscoveryCandidateConditionTags(
                conditionTags: candidate.conditionTags(for: selectedGoods)
            )
            .padding(.top, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openSelectedSheet()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            openSelectedSheet()
        }
        .accessibilityLabel("\(candidate.title)の詳細を見る")
        .accessibilityHint("タップで詳細を開きます。画像は横スワイプで切り替えられます。")
        .onAppear {
            selectedGoods = selectedGoods ?? candidate.goods.first
        }
        .onChange(of: candidate.goods.map(\.id)) { _, _ in
            selectedGoods = candidate.goods.first
        }
    }

    private var cardTitle: String {
        if titleStyle == .memberTag {
            return candidate.title
        }
        return HomeDiscoveryCardTitleFormatter.title(
            for: selectedGoods ?? candidate.goods.first,
            fallback: candidate.title,
            style: titleStyle
        )
    }

    private func openSelectedSheet() {
        onSelect(candidate.sheet(selectedGoods: selectedGoods))
    }
}

private struct HomeDiscoveryCandidateConditionTags: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HStack(spacing: 5) {
            tag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
            tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.accessibilityText)
    }

    private func tag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12.6, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.66)
            .padding(.horizontal, 8.5)
            .padding(.vertical, 4.8)
            .background(.white.opacity(0.92), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.28), lineWidth: 1)
            }
    }
}

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
                    let conditionTags = conditionTags(for: entry.goods)
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
                            handleTap(position: entry.position)
                        }
                    )
                    .accessibilityHidden(abs(entry.position) > 0.45)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .simultaneousGesture(dragGesture(width: proxy.size.width))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("グッズ画像を横スワイプで回転")
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
        DragGesture(minimumDistance: 4)
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
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        return absX > 6 && absX > absY * 1.15
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

private struct HomeRotaryEntry: Identifiable {
    var goods: HomeMockGoods
    var position: Double

    var id: UUID { goods.id }
}

struct HomeDiscoveryGoodsCard: View {
    var goods: HomeMockGoods
    var goodsCondition: HomeGoodsCondition
    var exchangeCondition: HomeExchangeCondition
    var paymentCondition: HomePaymentCondition
    var prominence: Double
    var showsConditionOverlay: Bool

    private var isFront: Bool {
        prominence > 0.72
    }

    var body: some View {
        ZStack {
            HomeGoodsArtwork(goods: goods)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(isFront ? 0.64 : 0.34), lineWidth: isFront ? 2 : 1.2)
        }
        .overlay(alignment: .topTrailing) {
            if isFront && showsConditionOverlay {
                HomeFloatingConditionTags(
                    goodsCondition: goodsCondition,
                    exchangeCondition: exchangeCondition,
                    paymentCondition: paymentCondition
                )
                .offset(x: 24, y: 6)
                .zIndex(100)
                .allowsHitTesting(false)
            }
        }
        .shadow(color: MegrumTheme.lavender.opacity(isFront ? 0.24 : 0.10), radius: isFront ? 14 : 7, y: isFront ? 8 : 4)
    }
}

private struct HomeFloatingConditionTags: View {
    var goodsCondition: HomeGoodsCondition
    var exchangeCondition: HomeExchangeCondition
    var paymentCondition: HomePaymentCondition

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            tag(title: goodsCondition.floatingTagTitle, color: goodsCondition.accent)
            tag(title: exchangeCondition.floatingTagTitle, color: exchangeCondition.accent)
            tag(title: paymentCondition.floatingTagTitle, color: paymentCondition.accent)
        }
        .fixedSize(horizontal: true, vertical: true)
        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func tag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.94), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.30), lineWidth: 1)
            }
    }
}

struct HomeConditionPill: View {
    var title: String
    var color: Color
    var compact: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: compact ? 11 : 13, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 6 : 8)
            .background(color.opacity(0.14), in: Capsule())
    }
}
