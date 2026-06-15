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
                hero
                copy
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

    private var hero: some View {
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
                GoodsStatusPill(text: presentation.statusLabel)
                    .padding(14)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 22, y: 12)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if !item.tags.isEmpty {
                FlowTags(tags: item.tags)
            }

            HStack(spacing: 12) {
                DetailMetric(label: context.quantityLabel, value: "\(max(1, item.quantity))")
                DetailMetric(label: "状態", value: presentation.statusLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GoodsReportSheet: View {
    var item: GoodsItem
    var onSubmit: (GoodsReportReason, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: GoodsReportReason = .fakeItem
    @State private var note = ""

    var body: some View {
        Form {
            Section("対象") {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Section("理由") {
                Picker("理由", selection: $reason) {
                    ForEach(GoodsReportReason.allCases) { reason in
                        Text(reason.displayName).tag(reason)
                    }
                }
            }

            Section("補足") {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("通報")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("送信") {
                    onSubmit(reason, note)
                    dismiss()
                }
            }
        }
    }
}

struct GoodsRemoteImage: View {
    var url: URL
    var cornerRadius: CGFloat
    var placeholderIconSize: CGFloat

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .success(image):
                GeometryReader { proxy in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            case .failure:
                GoodsImageFallback(iconSize: placeholderIconSize)
            @unknown default:
                GoodsImageFallback(iconSize: placeholderIconSize)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct GoodsImageFallback: View {
    var iconSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: iconSize, weight: .semibold))
            Text("表示できません")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.82))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GoodsTagPill: View {
    var name: String
    var fontSize: CGFloat
    var horizontalPadding: CGFloat

    var body: some View {
        GoodsTagTextPill(text: "# \(name)", fontSize: fontSize, horizontalPadding: horizontalPadding)
    }
}

struct GoodsTagTextPill: View {
    var text: String
    var fontSize: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat = 7

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(.white.opacity(0.86), in: Capsule())
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

struct GoodsQuantityBadge: View {
    var quantity: Int

    var body: some View {
        Text("×\(quantity)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(MegrumTheme.lavender, in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
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
