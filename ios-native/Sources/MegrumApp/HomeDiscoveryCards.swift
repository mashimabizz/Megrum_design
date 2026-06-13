import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
    var onSelect: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Spacer()
                Button {
                    if let firstCandidate = candidates.first {
                        onSelect(firstCandidate.sheet)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("すべて見る")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                }
                .buttonStyle(.plain)
                .disabled(candidates.isEmpty)
            }

            switch layout {
            case .grid:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22)], spacing: 14) {
                    ForEach(candidates) { candidate in
                        HomeDiscoveryCandidateButton(
                            candidate: candidate,
                            cardHeight: 158,
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
}

private struct HomeHavesCandidateButton: View {
    var candidate: HomeDiscoveryCandidate
    var onSelect: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(spacing: 7) {
            if let goods = candidate.goods.first {
                HomeDiscoveryGoodsCard(
                    goods: goods,
                    goodsCondition: candidate.goodsCondition,
                    exchangeCondition: candidate.exchangeCondition,
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
        .accessibilityValue("Wishまたは個別募集 \(countText)")
        .accessibilityHint("タップでこのグッズをWishに入れている人を見ます。")
    }

    private var countText: String {
        "\(candidate.linkedCount)件"
    }
}

private struct HomeDiscoveryCandidateButton: View {
    var candidate: HomeDiscoveryCandidate
    var cardHeight: CGFloat
    var onSelect: (HomeDiscoverySheet) -> Void

    @State private var selectedGoods: HomeMockGoods?

    var body: some View {
        VStack(spacing: 5) {
            HomeDiscoveryRotaryCard(
                goods: candidate.goods,
                goodsCondition: candidate.goodsCondition,
                exchangeCondition: candidate.exchangeCondition,
                showsConditionOverlay: false,
                onSelectionChange: { goods in
                    selectedGoods = goods
                },
                onActivate: { goods in
                    onSelect(candidate.sheet(selectedGoods: goods))
                }
            )
            .frame(height: max(118, cardHeight - 28))

            HomeDiscoveryCandidateConditionTags(
                goodsCondition: candidate.goodsCondition,
                exchangeCondition: candidate.exchangeCondition
            )

            Text(candidate.title)
                .font(.system(size: cardHeight > 150 ? 13.5 : 0, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .opacity(cardHeight > 150 ? 1 : 0)
                .frame(height: cardHeight > 150 ? 17 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    openSelectedSheet()
                }
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

    private func openSelectedSheet() {
        onSelect(candidate.sheet(selectedGoods: selectedGoods))
    }
}

private struct HomeDiscoveryCandidateConditionTags: View {
    var goodsCondition: HomeGoodsCondition
    var exchangeCondition: HomeExchangeCondition

    var body: some View {
        HStack(spacing: 5) {
            tag(title: goodsCondition.floatingTagTitle, color: goodsCondition.accent)
            tag(title: exchangeCondition.floatingTagTitle, color: exchangeCondition.accent)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func tag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
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
                    HomeDiscoveryGoodsCard(
                        goods: entry.goods,
                        goodsCondition: goodsCondition,
                        exchangeCondition: exchangeCondition,
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

                if goods.count > 1 {
                    pagePill
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, max(8, proxy.size.width * 0.14))
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                        .zIndex(40)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: proxy.size.width))
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

    private var displayedDragProgress: Double {
        reduceMotion ? 0 : dragProgress
    }

    private var countText: String {
        guard !goods.isEmpty else {
            return "0/0"
        }
        return "\(selectedIndex + 1)/\(goods.count)"
    }

    private var pagePill: some View {
        Text(countText)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.white.opacity(0.88), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
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
                let denominator = max(width * 0.58, 72)
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dragProgress = max(-1.15, min(1.15, -Double(value.translation.width / denominator)))
                }
            }
            .onEnded { value in
                guard goods.count > 1 else {
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
                    exchangeCondition: exchangeCondition
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

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            tag(title: goodsCondition.floatingTagTitle, color: goodsCondition.accent)
            tag(title: exchangeCondition.floatingTagTitle, color: exchangeCondition.accent)
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

enum HomeGoodsArtworkLayout {
    static func unit(in size: CGSize) -> CGFloat {
        max(1, min(size.width, size.height))
    }

    static func portraitHeadDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.43, size.width * 0.62, size.height * 0.38)
    }

    static func portraitBodySize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.40, size.width * 0.56),
            height: min(base * 0.58, size.height * 0.44)
        )
    }

    static func badgeDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.76, size.width * 0.82, size.height * 0.82)
    }

    static func standFigureSize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.34, size.width * 0.42),
            height: min(base * 0.74, size.height * 0.68)
        )
    }

    static func standBaseSize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.58, size.width * 0.76),
            height: min(base * 0.15, size.height * 0.14)
        )
    }

    static func keychainRingDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.20, size.width * 0.30, size.height * 0.18)
    }

    static func keychainHeartSize(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.62, size.width * 0.74, size.height * 0.66)
    }

    static func plushHeadDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.58, size.width * 0.68, size.height * 0.54)
    }

    static func plushBodySize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.54, size.width * 0.66),
            height: min(base * 0.36, size.height * 0.32)
        )
    }
}

struct HomeGoodsArtwork: View {
    var goods: HomeMockGoods

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: goods.palette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let imageURL = goods.imageURL {
                    HomeActualGoodsImage(url: imageURL, fallbackPalette: goods.palette)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    switch goods.shape {
                    case .portrait:
                        portrait(in: size)
                    case .badge:
                        badge(in: size)
                    case .stand:
                        stand(in: size)
                    case .keychain:
                        keychain(in: size)
                    case .plush:
                        plush(in: size)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func portrait(in size: CGSize) -> some View {
        let headDiameter = HomeGoodsArtworkLayout.portraitHeadDiameter(in: size)
        let bodySize = HomeGoodsArtworkLayout.portraitBodySize(in: size)

        return VStack(spacing: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.06)) {
            Circle()
                .fill(.white.opacity(0.30))
                .frame(width: headDiameter, height: headDiameter)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(9, headDiameter * 0.52), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

            Capsule()
                .fill(.white.opacity(0.28))
                .frame(width: bodySize.width, height: bodySize.height)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.34))
                        .frame(width: bodySize.width * 0.60, height: bodySize.height * 0.46)
                        .padding(.top, bodySize.height * 0.10)
                }
        }
        .shadow(color: .black.opacity(0.12), radius: max(4, HomeGoodsArtworkLayout.unit(in: size) * 0.08), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func badge(in size: CGSize) -> some View {
        let diameter = HomeGoodsArtworkLayout.badgeDiameter(in: size)

        return Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.90), MegrumTheme.sky.opacity(0.44), MegrumTheme.lavender.opacity(0.30)],
                    center: .center,
                    startRadius: 4,
                    endRadius: diameter * 0.75
                )
            )
            .frame(width: diameter, height: diameter)
            .overlay {
                Text(goods.symbol)
                    .font(.system(size: max(9, diameter * 0.36), weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .overlay(Circle().stroke(.white.opacity(0.88), lineWidth: max(1, diameter * 0.03)))
            .shadow(color: .black.opacity(0.12), radius: max(4, diameter * 0.09), y: max(2, diameter * 0.05))
    }

    private func stand(in size: CGSize) -> some View {
        let figureSize = HomeGoodsArtworkLayout.standFigureSize(in: size)
        let baseSize = HomeGoodsArtworkLayout.standBaseSize(in: size)

        return VStack(spacing: 0) {
            Capsule()
                .fill(MegrumTheme.lavender.opacity(0.30))
                .frame(width: figureSize.width, height: figureSize.height)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(8, figureSize.width * 0.62), weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }

            Ellipse()
                .fill(.white.opacity(0.78))
                .frame(width: baseSize.width, height: baseSize.height)
                .overlay(Ellipse().stroke(MegrumTheme.lavender.opacity(0.28), lineWidth: 1))
        }
        .shadow(color: .black.opacity(0.10), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func keychain(in size: CGSize) -> some View {
        let ringDiameter = HomeGoodsArtworkLayout.keychainRingDiameter(in: size)
        let heartSize = HomeGoodsArtworkLayout.keychainHeartSize(in: size)

        return VStack(spacing: -max(1, HomeGoodsArtworkLayout.unit(in: size) * 0.04)) {
            Circle()
                .stroke(MegrumTheme.lavender.opacity(0.54), lineWidth: max(1.2, ringDiameter * 0.18))
                .frame(width: ringDiameter, height: ringDiameter)

            Image(systemName: "heart.fill")
                .font(.system(size: heartSize, weight: .bold))
                .foregroundStyle(MegrumTheme.pink.opacity(0.70))
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(8, heartSize * 0.28), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
        }
        .shadow(color: .black.opacity(0.12), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func plush(in size: CGSize) -> some View {
        let headDiameter = HomeGoodsArtworkLayout.plushHeadDiameter(in: size)
        let bodySize = HomeGoodsArtworkLayout.plushBodySize(in: size)

        return VStack(spacing: -max(1, HomeGoodsArtworkLayout.unit(in: size) * 0.02)) {
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.48))
                .frame(width: headDiameter, height: headDiameter)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(9, headDiameter * 0.42), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            Capsule()
                .fill(MegrumTheme.lavender.opacity(0.35))
                .frame(width: bodySize.width, height: bodySize.height)
        }
        .shadow(color: .black.opacity(0.10), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }
}

private struct HomeActualGoodsImage: View {
    var url: URL
    var fallbackPalette: [Color]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: fallbackPalette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            loadedImage
        }
    }

    @ViewBuilder
    private var loadedImage: some View {
        if let platformImage = HomeLocalGoodsImageLoader.image(from: url) {
            platformImage
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

private enum HomeLocalGoodsImageLoader {
    static func image(from url: URL) -> Image? {
        guard url.isFileURL else {
            return nil
        }

        #if canImport(UIKit)
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }
        return Image(nsImage: image)
        #else
        return nil
        #endif
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
