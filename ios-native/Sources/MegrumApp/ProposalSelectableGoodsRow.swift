import Foundation
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
            thumbnail

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

    @ViewBuilder
    private var thumbnail: some View {
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

private struct ProposalSelectableGoodsRemoteThumbnail: View {
    var imageURL: URL

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            case .empty:
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius,
                style: .continuous
            )
        )
    }
}

private struct ProposalSelectableGoodsGlyphThumbnail: View {
    var item: GoodsItem

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.25))
                .frame(
                    width: ProposalSelectableGoodsRowMetrics.thumbnailShineSize,
                    height: ProposalSelectableGoodsRowMetrics.thumbnailShineSize
                )
                .offset(
                    x: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetX,
                    y: ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetY
                )
            Text(ProposalSelectableGoodsRowStyle.glyph(for: item))
                .font(.system(size: ProposalSelectableGoodsRowMetrics.glyphFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct ProposalSelectableGoodsCheckmark: View {
    var isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? MegrumTheme.lavender : Color.clear)
            .frame(
                width: ProposalSelectableGoodsRowMetrics.checkCircleSize,
                height: ProposalSelectableGoodsRowMetrics.checkCircleSize
            )
            .overlay {
                Circle()
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.16), lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    Text("✓")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
    }
}

enum ProposalSelectableGoodsRowStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("カリナ") {
            return "K"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func thumbnailColor(for item: GoodsItem) -> Color {
        if item.title.contains("ジョンウ") || item.title.contains("ニンニン") {
            return MegrumTheme.sky.opacity(0.72)
        }
        if item.title.contains("スア") {
            return MegrumTheme.lavender.opacity(0.64)
        }
        return MegrumTheme.pink.opacity(0.68)
    }
}
