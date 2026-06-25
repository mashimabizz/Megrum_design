import MegrumDesign
import SwiftUI

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

    private var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(
            goods: goodsCondition,
            exchange: exchangeCondition,
            payment: paymentCondition
        )
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            tag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
            if conditionTags.homeCandidateShowsExchangeTag {
                tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
            }
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .fixedSize(horizontal: true, vertical: true)
        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.homeCandidateAccessibilityText)
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
