import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalSelectableGoodsRemoteThumbnail: View {
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

struct ProposalSelectableGoodsGlyphThumbnail: View {
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

struct ProposalSelectableGoodsCheckmark: View {
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
