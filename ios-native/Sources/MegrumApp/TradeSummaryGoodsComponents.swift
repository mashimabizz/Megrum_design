import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeSummaryGoodsSection: View {
    var title: String
    var items: [GoodsItem]
    var expectedCount: Int
    var cashOffer: Bool
    var cashAmount: Int?

    private var displayCount: Int {
        max(items.count, expectedCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                Text(countText)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            if cashOffer && items.isEmpty {
                TradeCashAmountPanel(cashAmount: cashAmount)
            } else if items.isEmpty && displayCount > 0 {
                TradeSummaryEmptyText("\(displayCount)点（詳細を読み込み中）")
            } else if items.isEmpty {
                TradeSummaryEmptyText("未設定")
            } else {
                VStack(spacing: 9) {
                    ForEach(items) { item in
                        TradeSummaryGoodsRow(item: item)
                    }
                }

                if cashOffer {
                    TradeCashAmountPanel(cashAmount: cashAmount)
                }
            }
        }
        .padding(12)
        .background(MegrumTheme.lavender.opacity(0.06), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var countText: String {
        if cashOffer && items.isEmpty && displayCount == 0 {
            return "定価"
        }
        return "\(displayCount)点"
    }
}

struct TradeSummaryGoodsRow: View {
    var item: GoodsItem

    var body: some View {
        HStack(spacing: 10) {
            TradeSummaryGoodsThumb(item: item)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(item.tags.first?.name ?? "グッズ")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
    }
}

struct TradeSummaryGoodsThumb: View {
    var item: GoodsItem

    var body: some View {
        ZStack {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        TradeSummaryGoodsThumbFallback(title: item.title)
                    case .empty:
                        MegrumTheme.lavender.opacity(0.08)
                    @unknown default:
                        TradeSummaryGoodsThumbFallback(title: item.title)
                    }
                }
            } else {
                TradeSummaryGoodsThumbFallback(title: item.title)
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TradeSummaryGoodsThumbFallback: View {
    var title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.56), MegrumTheme.sky.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(title.first.map(String.init) ?? "M")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct TradeCashAmountPanel: View {
    var cashAmount: Int?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "yensign")
                .font(.system(size: 12, weight: .black))
            Text(cashText)
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(MegrumTheme.ok)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.ok.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var cashText: String {
        TradeAmountFormatter.fixedPrice(amount: cashAmount, fallback: "定価交換")
    }
}

struct TradeSummaryEmptyText: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
