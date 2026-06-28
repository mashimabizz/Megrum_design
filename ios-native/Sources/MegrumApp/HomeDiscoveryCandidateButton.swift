import MegrumDesign
import SwiftUI

struct HomeDiscoveryCandidateButton: View {
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
                    .font(.system(size: 14.5, weight: .regular))
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
            .padding(.top, 2)
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
