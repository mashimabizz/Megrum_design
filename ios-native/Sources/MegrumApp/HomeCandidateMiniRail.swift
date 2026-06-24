import MegrumDesign
import SwiftUI

enum HomeMiniCardStyle {
    case condition(String)
    case conditionTags(HomeConditionTagSet)
    case chips([String])
}

struct HomeCandidateMiniRail: View {
    var goods: [HomeMockGoods]
    var selectedIndex: Int
    var labels: [String] = []
    var conditionTagSets: [HomeConditionTagSet] = []
    var cardStyle: HomeMiniCardStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(goods.enumerated()), id: \.element.id) { index, goods in
                    HomeSelectableGoodsCard(
                        goods: goods,
                        selected: index == selectedIndex,
                        label: labels.indices.contains(index) ? labels[index] : nil,
                        style: conditionTagSets.indices.contains(index) ? .conditionTags(conditionTagSets[index]) : cardStyle
                    )
                    .frame(width: 118, height: 144)
                }
            }
            .padding(.trailing, 18)
        }
    }
}

struct HomeSelectableGoodsCard: View {
    var goods: HomeMockGoods
    var selected: Bool
    var label: String?
    var style: HomeMiniCardStyle

    var body: some View {
        VStack(spacing: 8) {
            HomeTinyGoodsThumbnail(goods: goods)
                .frame(height: 72)

            if let label {
                Text(label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }

            switch style {
            case .condition(let title):
                HomeConditionPill(title: title, color: MegrumTheme.pink, compact: true)
            case .conditionTags(let tags):
                HomeMiniConditionTagRows(conditionTags: tags)
            case .chips(let chips):
                FlexibleChipRows(chips: chips)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topLeading) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))
                .padding(8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: selected ? 1.6 : 1)
        }
    }
}

private struct HomeMiniConditionTagRows: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                tag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
                if conditionTags.homeCandidateShowsExchangeTag {
                    tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
                }
            }
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.homeCandidateAccessibilityText)
    }

    private func tag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9.2, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(.white.opacity(0.92), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.28), lineWidth: 1)
            }
    }
}

private struct FlexibleChipRows: View {
    var chips: [String]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(chips.chunked(into: 2).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { chip in
                        HomeConditionPill(
                            title: chip,
                            color: chipColor(chip),
                            compact: true
                        )
                    }
                }
            }
        }
    }

    private func chipColor(_ chip: String) -> Color {
        if chip.contains("提示") || chip.contains("PayPay") || chip.contains("差額") {
            return MegrumTheme.ok
        }
        if chip.contains("状態") || chip.contains("交換") || chip.contains("グッズ") {
            return MegrumTheme.sky
        }
        return MegrumTheme.lavender
    }
}
