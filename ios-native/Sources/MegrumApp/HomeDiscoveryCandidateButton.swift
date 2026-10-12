import MegrumDesign
import SwiftUI

struct HomeDiscoveryCandidateButton: View {
    var candidate: HomeDiscoveryCandidate
    var titleStyle: HomeDiscoveryCardTitleStyle
    var cardHeight: CGFloat
    var onSelect: (HomeDiscoverySheet) -> Void

    @State private var presentationState = HomeDiscoveryCandidateButtonPresentationState()

    var body: some View {
        VStack(spacing: 0) {
            // 塊ラベルは表示のみ（検索は走らせない）。iter1226.414。
            Text(cardTitle)
                .font(.system(size: 14.5, weight: .regular))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .center)
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
                    presentationState.select(goods)
                },
                onActivate: { goods in
                    onSelect(candidate.sheet(selectedGoods: goods))
                }
            )
            .frame(height: max(118, cardHeight - 42))

            HomeDiscoveryCandidateConditionTags(
                conditionTags: candidate.conditionTags(
                    for: presentationState.resolvedSelectedGoods(in: candidate.goods)
                )
            )
            .padding(.top, 2)
        }
        .onAppear {
            presentationState.hydrateIfNeeded(goods: candidate.goods)
        }
        .onChange(of: candidate.goods.map(\.id)) { _, _ in
            presentationState.resetSelection(goods: candidate.goods)
        }
    }

    private var cardTitle: String {
        presentationState.cardTitle(
            candidateTitle: candidate.title,
            titleStyle: titleStyle,
            goods: candidate.goods
        )
    }
}
