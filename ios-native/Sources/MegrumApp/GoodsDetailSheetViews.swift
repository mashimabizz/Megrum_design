import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsDetailSheet: View {
    var item: GoodsItem
    var context: GoodsGridContext
    @Environment(\.dismiss) private var dismiss

    private var presentation: GoodsTilePresentation {
        GoodsTilePresentation(item: item, context: context, isBusy: false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GoodsDetailHero(item: item, statusLabel: presentation.statusLabel)
                GoodsDetailCopy(
                    item: item,
                    quantityLabel: context.quantityLabel,
                    statusLabel: presentation.statusLabel
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("グッズ詳細")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct GoodsDetailHero: View {
    var item: GoodsItem
    var statusLabel: String

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        MegrumTheme.sky.opacity(0.6),
                        MegrumTheme.lavender.opacity(0.72),
                        MegrumTheme.pink.opacity(0.58)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(0.78, contentMode: .fit)
            .overlay {
                if let imageURL = item.imageURL {
                    GoodsRemoteImage(
                        url: imageURL,
                        cornerRadius: 28,
                        placeholderIconSize: 44
                    )
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .overlay(alignment: .topTrailing) {
                if let tag = item.tags.first {
                    GoodsTagPill(name: tag.name, fontSize: 13, horizontalPadding: 12)
                        .padding(14)
                }
            }
            .overlay(alignment: .topLeading) {
                GoodsStatusPill(text: statusLabel)
                    .padding(14)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 22, y: 12)
    }
}

private struct GoodsDetailCopy: View {
    var item: GoodsItem
    var quantityLabel: String
    var statusLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if !item.tags.isEmpty {
                FlowTags(tags: item.tags)
            }

            HStack(spacing: 12) {
                DetailMetric(label: quantityLabel, value: "\(max(1, item.quantity))")
                DetailMetric(label: "状態", value: statusLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GoodsStatusPill: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(MegrumTheme.ink.opacity(0.52), in: Capsule())
            .accessibilityHidden(true)
    }
}

private struct FlowTags: View {
    var tags: [GoodsTag]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags) { tag in
                GoodsTagPill(name: tag.name, fontSize: 12, horizontalPadding: 11)
            }
        }
    }
}

private struct DetailMetric: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
