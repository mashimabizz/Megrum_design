import MegrumDesign
import SwiftUI

struct HomeDiscoveryCandidateConditionTags: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HStack(spacing: 5) {
            tag(title: conditionTags.goods.floatingTagTitle, tone: conditionTags.goods.candidateChipTone)
            if conditionTags.homeCandidateShowsExchangeTag {
                tag(title: conditionTags.exchange.floatingTagTitle, tone: conditionTags.exchange.candidateChipTone)
            }
            tag(title: conditionTags.payment.floatingTagTitle, tone: conditionTags.payment.candidateChipTone)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.homeCandidateAccessibilityText)
    }

    @ViewBuilder
    private func tag(title: String, tone: HomeDiscoveryCandidateConditionChipTone) -> some View {
        switch tone {
        case .exact:
            baseText(title)
                .foregroundStyle(.white)
                .background(megrumGradient, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.42), lineWidth: 0.8)
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 8, y: 4)
        case .possible:
            baseText(title)
                .foregroundStyle(megrumGradient)
                .background(.white.opacity(0.96), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(megrumGradient, lineWidth: 1.15)
                }
        case .uncertain:
            baseText(title)
                .foregroundStyle(MegrumTheme.muted)
                .background(Color.white.opacity(0.92), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(MegrumTheme.muted.opacity(0.24), lineWidth: 1)
                }
        }
    }

    private func baseText(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12.6, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.66)
            .padding(.horizontal, 8.5)
            .padding(.vertical, 4.8)
    }

    private var megrumGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum HomeDiscoveryCandidateConditionChipTone {
    case exact
    case possible
    case uncertain
}

private extension HomeGoodsCondition {
    var candidateChipTone: HomeDiscoveryCandidateConditionChipTone {
        switch self {
        case .direct:
            .exact
        case .wish:
            .possible
        case .none:
            .uncertain
        }
    }
}

private extension HomeExchangeCondition {
    var candidateChipTone: HomeDiscoveryCandidateConditionChipTone {
        switch self {
        case .exact:
            .exact
        case .possible:
            .possible
        case .warning:
            .uncertain
        }
    }
}

private extension HomePaymentCondition {
    var candidateChipTone: HomeDiscoveryCandidateConditionChipTone {
        switch self {
        case .exact:
            .exact
        case .compatible:
            .possible
        case .unknown, .warning:
            .uncertain
        }
    }
}
