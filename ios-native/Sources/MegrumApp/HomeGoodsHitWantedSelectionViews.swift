import Foundation
import MegrumDesign
import SwiftUI

/// 相手の希望が「条件指定」の選択肢のとき、条件を1枚のカードで見せるためのモデル。iter1226.371。
struct HomeWantedConditionCardModel: Equatable {
    var tokens: [String]
    var isTentative: Bool
    var isSelected: Bool

    static func tokens(from option: HomeIndividualListingWantedOption) -> [String] {
        // 条件指定はマッチしたグッズ名ではなく募集の条件そのものを見せる。iter1226.371。
        var tokens = [option.conditionSummary?.nilIfBlank ?? option.title]
        if let subtitle = option.subtitle?.nilIfBlank,
           !subtitle.localizedCaseInsensitiveContains("該当するグッズ"),
           subtitle != option.title {
            tokens.append(subtitle)
        }
        return tokens.filter { !$0.isEmpty }
    }
}

struct HomeGoodsHitWantedSelectionRail: View {
    var usesListingWantedOptions: Bool
    var wantedOptionPreviewGoods: [HomeMockGoods]
    var selectedWantedOptionPreviewIndices: Set<Int>
    var topTrailingBadgeTextByGoodsID: [UUID: String]
    var wantedGoods: [HomeMockGoods]
    var selectedWantedIndices: Set<Int>
    var cardSize: HomeGoodsImagePanelCardSize
    /// 条件指定の選択肢の場合はマッチしたグッズ列ではなく条件カードを1枚出す。iter1226.371。
    var conditionCard: HomeWantedConditionCardModel? = nil
    var onSelectWantedOptionPreviewGoods: (Int) -> Void
    var onSelectWantedGoods: (Int) -> Void
    var onToggleConditionCard: () -> Void = {}

    var body: some View {
        if let conditionCard {
            HomeWantedConditionCard(model: conditionCard, cardSize: cardSize, onToggle: onToggleConditionCard)
        } else if usesListingWantedOptions, !wantedOptionPreviewGoods.isEmpty {
            HomeGoodsImagePanelRail(
                goods: wantedOptionPreviewGoods,
                selectedIndices: selectedWantedOptionPreviewIndices,
                topTrailingBadgeTextByGoodsID: topTrailingBadgeTextByGoodsID,
                cardSize: cardSize,
                onSelect: onSelectWantedOptionPreviewGoods
            )
        } else {
            HomeGoodsImagePanelRail(
                goods: wantedGoods,
                selectedIndices: selectedWantedIndices,
                cardSize: cardSize,
                onSelect: onSelectWantedGoods
            )
        }
    }
}

private struct HomeWantedConditionCard: View {
    var model: HomeWantedConditionCardModel
    var cardSize: HomeGoodsImagePanelCardSize
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: model.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(model.isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.28))
                        .symbolRenderingMode(.hierarchical)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(model.isTentative ? "条件（？）" : "条件")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.tokens.prefix(3), id: \.self) { token in
                        Text(token)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(11)
            .frame(width: max(cardSize.width * 2.1, 190), alignment: .leading)
            .frame(minHeight: cardSize.height + 24, alignment: .topLeading)
            .background(MegrumTheme.lavender.opacity(model.isSelected ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        model.isSelected ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.25),
                        lineWidth: model.isSelected ? 2.2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("相手の希望条件 " + model.tokens.joined(separator: "、"))
        .accessibilityAddTraits(model.isSelected ? [.isSelected] : [])
    }
}

struct HomeWantedSelectionSectionHeader: View {
    var systemName: String
    var title: String
    var trailing: String?
    var showsOtherOptionsButton: Bool
    var onOpenOtherOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 24, height: 24)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    if let trailing {
                        Text(trailing)
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsOtherOptionsButton {
                    Button("他の選択肢", systemImage: "list.bullet.rectangle", action: onOpenOtherOptions)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .padding(.horizontal, 9)
                        .frame(height: 30)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}
