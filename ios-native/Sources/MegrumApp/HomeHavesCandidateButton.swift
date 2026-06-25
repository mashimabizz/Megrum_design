import MegrumDesign
import SwiftUI

struct HomeHavesCandidateButton: View {
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
