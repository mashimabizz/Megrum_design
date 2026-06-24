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
    var showsSeeAllButton = false
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearchCandidate: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void = { _, _ in }

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
                            onSelect: onSelect,
                            onSearch: onSearchCandidate
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
    var onSearch: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void

    @State private var selectedGoods: HomeMockGoods?

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onSearch(candidate, selectedGoods ?? candidate.goods.first)
            } label: {
                Text(cardTitle)
                    .font(.system(size: 14.5, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(cardTitle)で検索")
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
}

private struct HomeDiscoveryCandidateConditionTags: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HStack(spacing: 5) {
            tag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
            if conditionTags.homeCandidateShowsExchangeTag {
                tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
            }
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.homeCandidateAccessibilityText)
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
