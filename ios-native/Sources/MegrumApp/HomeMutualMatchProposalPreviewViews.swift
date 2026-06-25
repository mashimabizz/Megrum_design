import MegrumDesign
import SwiftUI

struct HomeMutualMatchPreviewSide: View {
    var title: String
    var item: HomeMutualMatchProposalItem
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                HomeMutualMatchDisplayArtwork(item: item, tint: tint)
                    .frame(height: 92)

                Text(title)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.92), in: Capsule())
                    .padding(6)
            }

            Text(item.title)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if item.data.kind != .goods, !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeMutualMatchDisplayArtwork: View {
    var item: HomeMutualMatchProposalItem
    var tint: Color

    var body: some View {
        Group {
            if let goods = item.goods {
                HomeTinyGoodsThumbnail(goods: goods)
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay {
                        VStack(spacing: 7) {
                            Image(systemName: item.data.kind == .fixedPrice ? "tag.fill" : "yensign.circle.fill")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(tint)
                            Text(item.title)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                                    .foregroundStyle(tint)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(tint.opacity(0.28), lineWidth: 1)
                    }
            }
        }
        .accessibilityLabel(item.title)
    }
}
