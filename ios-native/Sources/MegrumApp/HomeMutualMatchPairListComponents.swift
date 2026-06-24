import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeMutualMatchPairButton: View {
    var pair: HomeMutualMatchProposalPair
    var isSelected: Bool
    var showsConditionTags: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    HomeMutualMatchPairSide(
                        title: "求めるグッズ",
                        item: pair.receiverDisplayItem,
                        tint: MegrumTheme.lavender
                    )

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 24)

                    HomeMutualMatchPairSide(
                        title: "譲るグッズ",
                        item: pair.senderDisplayItem,
                        tint: MegrumTheme.pink
                    )

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.42))
                }

                if showsConditionTags {
                    HomeMutualMatchConditionTagRow(conditionTags: pair.conditionTags)
                }
            }
            .padding(12)
            .background(
                isSelected ? MegrumTheme.lavender.opacity(0.12) : .white.opacity(0.80),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? MegrumTheme.lavender.opacity(0.52) : MegrumTheme.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pair.receiverDisplayItem.title)と\(pair.senderDisplayItem.title)の組み合わせ")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct HomeMutualMatchPairSide: View {
    var title: String
    var item: HomeMutualMatchProposalItem
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            HomeMutualMatchDisplayArtwork(item: item, tint: tint)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(tint)

                Text(item.title)
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                if item.data.kind != .goods, !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HomeOtherMutualMatchPairsSection: View {
    var pairs: [HomeMutualMatchProposalPair]
    var selectedPairID: String?
    var onSelect: (HomeMutualMatchProposalPair) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text("個別募集同士でヒット")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)

                Spacer(minLength: 0)

                Text("\(pairs.count)件")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(pairs) { pair in
                    HomeMutualMatchPairButton(
                        pair: pair,
                        isSelected: selectedPairID == pair.id,
                        showsConditionTags: false
                    ) {
                        onSelect(pair)
                    }
                }
            }
        }
    }
}

struct HomeMutualMatchConditionTagRow: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        HStack(spacing: 6) {
            conditionTag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
            conditionTag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
            conditionTag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
            Spacer(minLength: 0)
        }
    }

    private func conditionTag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: Capsule())
    }
}
