import MegrumDesign
import SwiftUI

struct HomeDiscoveryCandidateConditionTags: View {
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
