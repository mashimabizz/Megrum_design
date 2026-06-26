import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalConfirmExchangeArtwork: View {
    var goods: [GoodsItem]
    var cashAmount: Int?
    var tint: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let first = goods.first {
                ProposalConfirmGoodsArtwork(item: first)
            } else {
                ProposalConfirmCashArtwork(cashAmount: cashAmount, tint: tint)
            }

            if displayCount > 1 {
                ProposalConfirmExchangeArtworkCountBadge(count: displayCount)
            }
        }
    }

    private var displayCount: Int {
        goods.count + (cashAmount == nil ? 0 : 1)
    }
}

private struct ProposalConfirmCashArtwork: View {
    var cashAmount: Int?
    var tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(tint.opacity(0.12))
            .overlay {
                VStack(spacing: 7) {
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(tint)
                    Text(cashAmount.map(TradeAmountFormatter.compactYen) ?? "未選択")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.horizontal, 8)
            }
    }
}

private struct ProposalConfirmExchangeArtworkCountBadge: View {
    var count: Int

    var body: some View {
        Text("\(count)件")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.white.opacity(0.92), in: Capsule())
            .padding(6)
    }
}

struct ProposalConfirmGoodsArtwork: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            ProposalConfirmGoodsArtworkFallback(title: item.title)
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        @unknown default:
                            ProposalConfirmGoodsArtworkFallback(title: item.title)
                        }
                    }
                } else {
                    ProposalConfirmGoodsArtworkFallback(title: item.title)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct ProposalConfirmGoodsArtworkFallback: View {
    var title: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 56, height: 56)
                .offset(x: -20, y: -22)
            Text(ProposalPreviewGlyphResolver.glyph(for: title))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
    }
}
