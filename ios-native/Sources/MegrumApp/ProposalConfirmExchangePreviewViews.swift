import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalExchangePreviewRow: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int? = nil
    var receiverCashAmount: Int? = nil

    @State private var showsItemList = false

    private var hasMultipleItems: Bool {
        senderGoods.count > 1 || receiverGoods.count > 1
    }

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
            .overlay(alignment: .topTrailing) {
                if hasMultipleItems {
                    HStack(spacing: 3) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 10, weight: .black))
                        Text("一覧")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                    .padding(10)
                    .allowsHitTesting(false)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture {
                guard hasMultipleItems else {
                    return
                }
                showsItemList = true
            }
            .sheet(isPresented: $showsItemList) {
                ProposalExchangeItemListSheet(
                    senderGoods: senderGoods,
                    receiverGoods: receiverGoods,
                    senderCashAmount: senderCashAmount,
                    receiverCashAmount: receiverCashAmount
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .accessibilityHint(hasMultipleItems ? "タップでグッズの一覧を表示" : "")
    }
}

/// 打診の送信確認画面から開く、受け取るもの／私が出すものの全一覧シート。
struct ProposalExchangeItemListSheet: View {
    var senderGoods: [GoodsItem]
    var receiverGoods: [GoodsItem]
    var senderCashAmount: Int?
    var receiverCashAmount: Int?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    itemSection(
                        title: "受け取るもの",
                        goods: receiverGoods,
                        cashAmount: receiverCashAmount,
                        tint: MegrumTheme.lavender
                    )
                    itemSection(
                        title: "私が出すもの",
                        goods: senderGoods,
                        cashAmount: senderCashAmount,
                        tint: MegrumTheme.pink
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("交換するグッズ")
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

    @ViewBuilder
    private func itemSection(title: String, goods: [GoodsItem], cashAmount: Int?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                Text("\(goods.count + (cashAmount != nil ? 1 : 0))件")
                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            if goods.isEmpty && cashAmount == nil {
                Text("なし")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            ForEach(goods) { item in
                HStack(spacing: 12) {
                    ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 10)
                        .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                        if item.quantity > 1 {
                            Text("数量 \(item.quantity)")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let cashAmount {
                HStack(spacing: 12) {
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 52, height: 52)
                    Text(TradeAmountFormatter.fixedPrice(amount: cashAmount))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
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
