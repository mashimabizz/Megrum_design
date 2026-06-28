import MegrumCore
import MegrumDesign
import Foundation
import SwiftUI

enum GoodsQuickActionPresentationMetrics {
    static let backdropOpacity: Double = 0.12
    static let panelTransitionScale: CGFloat = 0.96
    static let panelAnimationResponse: Double = 0.34
    static let panelAnimationDampingFraction: Double = 0.86
}

enum GoodsQuickActionPreviewMetrics {
    static let width: CGFloat = 50
    static let height: CGFloat = 64
    static let cornerRadius: CGFloat = 14
    static let fallbackGlyphFontSize: CGFloat = 24
}

struct GoodsQuickActionHeaderPresentation: Equatable {
    var masterLine: String
    var tagLine: String

    init(item: GoodsItem, l1Name: String? = nil, l2Name: String? = nil) {
        let masterNames = [l1Name, l2Name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        masterLine = masterNames.isEmpty ? item.title : masterNames.joined(separator: "　")

        let tagNames = TagNameNormalizer.uniquePreservingOrder(
            item.tags.map(\.name),
            limit: item.tags.count
        )
        let visibleTagNames = Array(tagNames.prefix(3))
        var tagParts = visibleTagNames.map { "#\($0)" }
        if tagNames.count > visibleTagNames.count {
            tagParts.append("+\(tagNames.count - visibleTagNames.count)")
        }
        tagLine = tagParts.isEmpty ? "シリーズ未設定" : tagParts.joined(separator: " ")
    }
}

struct GoodsQuickActionBackdrop: View {
    var onDismiss: () -> Void

    var body: some View {
        Color.black.opacity(GoodsQuickActionPresentationMetrics.backdropOpacity)
            .ignoresSafeArea()
            .onTapGesture(perform: onDismiss)
            .accessibilityLabel("メニューを閉じる")
    }
}

struct GoodsCollectionQuickActionPanel: View {
    var item: GoodsItem
    var headerPresentation: GoodsQuickActionHeaderPresentation?
    var actions: [GoodsQuickActionKind] = GoodsQuickActionKind.inventoryActions
    var onAction: (GoodsQuickActionKind) -> Void

    private var header: GoodsQuickActionHeaderPresentation {
        headerPresentation ?? GoodsQuickActionHeaderPresentation(item: item)
    }

    var body: some View {
        MegrumGlassGroup(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    GoodsQuickActionItemPreview(item: item)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(header.masterLine)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(MegrumTheme.ink)

                        Text(header.tagLine)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Spacer(minLength: 0)
                }

                ForEach(actions) { action in
                    Button(role: action.role) {
                        onAction(action)
                    } label: {
                        let actionTitle = action.title(for: item.status)
                        HStack(spacing: 10) {
                            Image(systemName: action.systemImage)
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 22)

                            Text(actionTitle)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))

                            Spacer()
                        }
                        .foregroundStyle(action.role == .destructive ? Color.red : MegrumTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .megrumLiquidGlass(
                            .rounded(cornerRadius: 17),
                            tint: (action.role == .destructive ? Color.red : MegrumTheme.lavender).opacity(0.12),
                            interactive: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(action.title(for: item.status))
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.46), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 24, y: 14)
            .megrumLiquidGlass(.rounded(cornerRadius: 28), tint: Color.white.opacity(0.18))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct GoodsQuickActionItemPreview: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: GoodsQuickActionPreviewMetrics.cornerRadius, style: .continuous)
            .fill(GoodsTileCollectionCardStyle.hue(for: item))
            .frame(width: GoodsQuickActionPreviewMetrics.width, height: GoodsQuickActionPreviewMetrics.height)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        case .failure:
                            fallbackPreview
                        default:
                            ProgressView()
                                .tint(.white)
                        }
                    }
                } else {
                    fallbackPreview
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GoodsQuickActionPreviewMetrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GoodsQuickActionPreviewMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.78), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private var fallbackPreview: some View {
        Text(GoodsTileCollectionCardStyle.glyph(for: item))
            .font(.system(size: GoodsQuickActionPreviewMetrics.fallbackGlyphFontSize, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }
}
