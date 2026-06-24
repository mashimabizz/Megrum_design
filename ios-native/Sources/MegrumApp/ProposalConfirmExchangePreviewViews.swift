import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int? = nil
    var receiverCashAmount: Int? = nil

    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 12)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if senderCashAmount == nil, receiverCashAmount == nil {
            TradeDealGoodsPanel(
                offeredItems: senderGoods,
                requestedItems: receiverGoods,
                offeredTitle: "私が出すもの",
                requestedTitle: "受け取るもの",
                offeredEmptyTitle: "未選択",
                requestedEmptyTitle: "未選択"
            )
        } else {
            ProposalCashCompatibleExchangePreviewRow(
                senderGoods: senderGoods,
                receiverGoods: receiverGoods,
                senderCashAmount: senderCashAmount,
                receiverCashAmount: receiverCashAmount
            )
        }
    }
}

private struct ProposalCashCompatibleExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int?
    var receiverCashAmount: Int?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ProposalPreviewSide(
                title: "受け取るもの",
                goods: receiverGoods,
                cashAmount: receiverCashAmount
            )
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(MegrumTheme.muted.opacity(0.64))
                .frame(width: 26)
            ProposalPreviewSide(
                title: "私が出すもの",
                goods: senderGoods,
                cashAmount: senderCashAmount,
                isMine: true
            )
        }
    }
}

private struct ProposalPreviewSide: View {
    var title: String
    var goods: [GoodsItem]
    var cashAmount: Int?
    var isMine = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .black, design: .rounded))
                .foregroundStyle(tint)

            ProposalConfirmExchangeArtwork(
                goods: goods,
                cashAmount: cashAmount,
                tint: tint
            )
            .frame(height: 104)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tint: Color {
        isMine ? MegrumTheme.pink : MegrumTheme.lavender
    }

}

private struct ProposalConfirmExchangeArtwork: View {
    var goods: [GoodsItem]
    var cashAmount: Int?
    var tint: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let first = goods.first {
                ProposalConfirmGoodsArtwork(item: first)
            } else {
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

            if displayCount > 1 {
                Text("\(displayCount)件")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.92), in: Capsule())
                    .padding(6)
            }
        }
    }

    private var displayCount: Int {
        goods.count + (cashAmount == nil ? 0 : 1)
    }
}

private struct ProposalConfirmGoodsArtwork: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallback
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        @unknown default:
                            fallback
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 56, height: 56)
                .offset(x: -20, y: -22)
            Text(ProposalPreviewGlyphResolver.glyph(for: item.title))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
    }
}

enum ProposalPreviewGlyphResolver {
    static func glyph(for title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.contains("カリナ") {
            return "K"
        }
        if trimmedTitle.contains("ジョンウ") {
            return "J"
        }
        if trimmedTitle.contains("スア") {
            return "S"
        }
        if trimmedTitle.contains("ニンニン") {
            return "N"
        }
        guard let firstCharacter = trimmedTitle.first else {
            return "?"
        }
        return String(firstCharacter)
    }
}
