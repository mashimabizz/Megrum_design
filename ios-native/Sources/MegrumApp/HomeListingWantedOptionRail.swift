import Foundation
import MegrumDesign
import SwiftUI

struct HomeListingWantedOptionRail: View {
    var options: [HomeIndividualListingWantedOption]
    var selectedIndices: Set<Int>
    var previewGoodsByOptionID: [UUID: HomeMockGoods]
    var isSelectionEnabled: Bool = true
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    if isSelectionEnabled {
                        Button {
                            onSelect(index)
                        } label: {
                            optionCard(option: option, index: index)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                    } else {
                        optionCard(option: option, index: index)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(option.title)
                    }
                }
            }
            .padding(.trailing, 18)
        }
    }

    private func optionCard(option: HomeIndividualListingWantedOption, index: Int) -> some View {
        HomeListingWantedOptionCard(
            option: option,
            selected: selectedIndices.contains(index),
            previewGoods: previewGoodsByOptionID[option.id],
            showsSelectionIndicator: isSelectionEnabled
        )
        .frame(width: 118, height: 144)
    }
}

private struct HomeListingWantedOptionCard: View {
    var option: HomeIndividualListingWantedOption
    var selected: Bool
    var previewGoods: HomeMockGoods?
    var showsSelectionIndicator: Bool

    var body: some View {
        Group {
            if let previewGoods {
                imageOptionCard(previewGoods)
            } else {
                optionTextCard
            }
        }
    }

    private func imageOptionCard(_ previewGoods: HomeMockGoods) -> some View {
        HomeImagePanelGoodsCard(
            goods: previewGoods,
            selected: selected,
            selectedBannerText: nil,
            showsSelectionIndicator: showsSelectionIndicator
        )
        .overlay(alignment: .topTrailing) {
            if option.kind != .goods {
                optionKindBadge
                    .padding(8)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let subtitle = option.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.54)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var optionTextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 24)

            Text(option.title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.74)

            if let subtitle = option.subtitle {
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            if showsSelectionIndicator {
                selectionBadge
                    .padding(9)
            }
        }
        .overlay(alignment: .topTrailing) {
            optionKindBadge
                .padding(9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                    lineWidth: selected ? 2.2 : 1
                )
        }
        .shadow(color: .black.opacity(selected ? 0.16 : 0.08), radius: selected ? 12 : 7, y: selected ? 6 : 3)
    }

    private var selectionBadge: some View {
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.5))
    }

    private var optionKindBadge: some View {
        Image(systemName: symbolName)
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(width: 32, height: 32)
            .background(MegrumTheme.lavender.opacity(0.13), in: Circle())
    }

    private var symbolName: String {
        switch option.kind {
        case .goods:
            "shippingbox.fill"
        case .condition:
            "line.3.horizontal.decrease.circle.fill"
        case .cash:
            "yensign.circle.fill"
        }
    }
}
