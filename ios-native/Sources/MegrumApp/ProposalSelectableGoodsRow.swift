import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalSelectableGoodsRow: View {
    var item: GoodsItem
    var isSelected: Bool
    var hintText: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: ProposalSelectableGoodsRowMetrics.rowSpacing) {
            ProposalSelectableGoodsThumbnail(item: item)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
                Text(hintText)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.sky)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(MegrumTheme.sky.opacity(0.22), in: Capsule())
            }

            Spacer()

            ProposalSelectableGoodsCheckmark(isSelected: isSelected)
        }
        .padding(ProposalSelectableGoodsRowMetrics.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            rowBackground,
            in: RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous)
                .stroke(rowBorderColor, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.rowCornerRadius, style: .continuous))
        .onTapGesture(perform: action)
        .accessibilityLabel(item.title)
        .accessibilityValue(isSelected ? "選択中" : "未選択")
        .accessibilityAddTraits(.isButton)
    }

    private var subtitleText: String {
        item.tags.map(\.name).prefix(2).joined(separator: " / ")
    }

    private var rowBackground: Color {
        isSelected ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBackgroundOpacity) : .white
    }

    private var rowBorderColor: Color {
        isSelected
            ? MegrumTheme.lavender.opacity(ProposalSelectableGoodsRowMetrics.selectedBorderOpacity)
            : MegrumTheme.ink.opacity(ProposalSelectableGoodsRowMetrics.defaultBorderOpacity)
    }
}

private struct ProposalSelectableGoodsThumbnail: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius, style: .continuous)
            .fill(ProposalSelectableGoodsRowStyle.thumbnailColor(for: item))
            .frame(
                width: ProposalSelectableGoodsRowMetrics.thumbnailWidth,
                height: ProposalSelectableGoodsRowMetrics.thumbnailHeight
            )
            .overlay {
                if let imageURL = item.imageURL {
                    ProposalSelectableGoodsRemoteThumbnail(imageURL: imageURL)
                } else {
                    ProposalSelectableGoodsGlyphThumbnail(item: item)
                }
            }
    }
}
