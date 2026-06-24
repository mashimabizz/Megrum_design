import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsCarouselStage: View {
    var items: [GoodsItem]
    var selectedIndex: Int
    var dragProgress: Double
    var tableRotation: Double
    var accentColor: Color
    var badgeTitle: String?

    var body: some View {
        GeometryReader { proxy in
            let heroWidth = min(max(proxy.size.width * 0.58, 76), 96)
            let heroHeight = min(proxy.size.height - 32, 132)
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.24), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 4,
                            endRadius: heroWidth * 0.72
                        )
                    )
                    .frame(width: min(proxy.size.width * 0.82, 126), height: 24)
                    .offset(y: heroHeight * 0.43)
                    .accessibilityHidden(true)

                TradeRotatingGoodsTable(accentColor: accentColor, rotation: tableRotation)
                    .frame(width: min(proxy.size.width * 0.86, 136), height: 48)
                    .offset(y: heroHeight * 0.43)
                    .zIndex(0)

                ForEach(visibleEntries) { entry in
                    let metrics = TradeGoodsCarouselLayout.cardMetrics(
                        for: entry.position,
                        heroWidth: heroWidth,
                        heroHeight: heroHeight,
                        stageWidth: proxy.size.width
                    )
                    TradeGoodsOrbitCard(
                        item: entry.item,
                        accentColor: accentColor,
                        prominence: metrics.prominence,
                        badgeTitle: badgeTitle
                    )
                    .frame(width: metrics.width, height: metrics.height)
                    .rotation3DEffect(
                        Angle.degrees(metrics.yaw),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.72
                    )
                    .offset(x: metrics.xOffset, y: metrics.yOffset)
                    .opacity(metrics.opacity)
                    .zIndex(metrics.zIndex)
                    .accessibilityHidden(abs(entry.position) > 0.45)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityHidden(true)
    }

    private var visibleEntries: [TradeGoodsCarouselEntry] {
        items.indices
            .map { index in
                TradeGoodsCarouselEntry(
                    item: items[index],
                    position: relativePosition(for: index)
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.position) == abs(rhs.position) {
                    return lhs.position < rhs.position
                }
                return abs(lhs.position) < abs(rhs.position)
            }
            .prefix(3)
            .sorted { lhs, rhs in
                lhs.position < rhs.position
            }
    }

    private func relativePosition(for index: Int) -> Double {
        guard !items.isEmpty else {
            return 0
        }
        let count = items.count
        let forward = (index - selectedIndex + count) % count
        let backward = (selectedIndex - index + count) % count
        let shortest = forward <= backward ? Double(forward) : -Double(backward)
        return shortest - dragProgress
    }
}

private struct TradeGoodsCarouselEntry: Identifiable {
    var item: GoodsItem
    var position: Double

    var id: GoodsItem.ID {
        item.id
    }
}

private struct TradeGoodsOrbitCard: View {
    var item: GoodsItem
    var accentColor: Color
    var prominence: Double
    var badgeTitle: String?

    private var clampedProminence: Double {
        max(0, min(prominence, 1))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TradeGoodsArtwork(item: item, accentColor: accentColor)

            if let badgeTitle, clampedProminence > 0.70 {
                Text(badgeTitle)
                    .font(.system(size: 9.5 + CGFloat(clampedProminence) * 1.2, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.94), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(accentColor.opacity(0.20), lineWidth: 0.8)
                    }
                    .padding(6)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 13 + CGFloat(clampedProminence), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13 + CGFloat(clampedProminence), style: .continuous)
                .strokeBorder(accentColor.opacity(0.44 + clampedProminence * 0.12), lineWidth: 1.2 + CGFloat(clampedProminence) * 0.45)
        }
        .shadow(color: accentColor.opacity(0.15 + clampedProminence * 0.08), radius: 8 + CGFloat(clampedProminence) * 4, y: 6)
    }
}

private struct TradeRotatingGoodsTable: View {
    var accentColor: Color
    var rotation: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(accentColor.opacity(0.14))
                .blur(radius: 5)
                .offset(y: 7)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.96),
                            accentColor.opacity(0.24),
                            MegrumTheme.sky.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.78),
                            accentColor.opacity(0.20),
                            accentColor.opacity(0.02)
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 56
                    )
                )
                .scaleEffect(x: 0.82, y: 0.54)

            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    Capsule()
                        .fill(tableHighlightColor(for: index))
                        .frame(width: index.isMultiple(of: 2) ? 30 : 19, height: 2.8)
                        .offset(x: index.isMultiple(of: 2) ? 48 : 40)
                        .rotationEffect(.degrees(Double(index) * 36))
                }
            }
            .rotationEffect(.degrees(rotation))
            .clipShape(Ellipse())

            Capsule()
                .fill(.white.opacity(0.62))
                .frame(width: 82, height: 4)
                .blur(radius: 0.4)
                .offset(y: 14)

            Ellipse()
                .strokeBorder(.white.opacity(0.84), lineWidth: 1.4)

            Ellipse()
                .strokeBorder(accentColor.opacity(0.30), lineWidth: 4.4)
                .scaleEffect(x: 0.88, y: 0.66)
                .blur(radius: 0.8)
        }
        .shadow(color: accentColor.opacity(0.20), radius: 13, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .accessibilityHidden(true)
    }

    private func tableHighlightColor(for index: Int) -> Color {
        if index.isMultiple(of: 2) {
            return accentColor.opacity(0.46)
        }
        return MegrumTheme.sky.opacity(0.34)
    }
}

private struct TradeGoodsArtwork: View {
    var item: GoodsItem
    var accentColor: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    accentColor.opacity(0.42),
                    MegrumTheme.sky.opacity(0.25),
                    .white.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                            .tint(accentColor)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .clipped()
    }

    private var fallback: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))

            Text(TradePreviewThumbnailStyle.glyph(for: item))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}

struct TradeGoodsEmptyCarouselStage: View {
    var title: String
    var accentColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(accentColor.opacity(0.10))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.badge.questionmark")
                        .font(.system(size: 22, weight: .bold))
                    Text(title)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(accentColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            .accessibilityLabel(title)
    }
}
