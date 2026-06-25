import MegrumDesign
import SwiftUI

struct HomeSelectedGoodsHeader: View {
    var title: String = "選んだグッズ"
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet
    var exchangeSummary: HomeDiscoveryOwnerExchangeSummary?
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                HomeSelectedGoodsSingleCard(goods: goods, conditionTags: conditionTags)
                    .frame(width: 136, height: 162)

                VStack(alignment: .leading, spacing: 10) {
                    if let ownerSummary = goods.ownerSummary {
                        HomeUserSummary(owner: ownerSummary, onOpenProfile: onOpenOwnerProfile)
                    }

                    if let exchangeSummary {
                        HomeExchangeMethodBlock(summary: exchangeSummary)
                    }

                    HomePaymentBox(summaryText: goods.ownerPaymentSummaryText)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct HomeSelectedGoodsSingleCard: View {
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HomeDiscoveryGoodsCard(
            goods: goods,
            goodsCondition: conditionTags.goods,
            exchangeCondition: conditionTags.exchange,
            paymentCondition: conditionTags.payment,
            prominence: 1,
            showsConditionOverlay: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("選んだグッズ")
    }
}
