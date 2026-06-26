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
        ProposalExchangePreviewRowContent(
            senderGoods: senderGoods,
            receiverGoods: receiverGoods,
            senderCashAmount: senderCashAmount,
            receiverCashAmount: receiverCashAmount
        )
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
            }
    }
}

private struct ProposalExchangePreviewRowContent: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int?
    var receiverCashAmount: Int?

    var body: some View {
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
