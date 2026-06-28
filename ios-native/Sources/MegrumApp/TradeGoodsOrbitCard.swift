import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeGoodsOrbitCard: View {
    var item: TradeDealDisplayItem
    var accentColor: Color
    var prominence: Double
    var badgeTitle: String?

    private var clampedProminence: Double {
        max(0, min(prominence, 1))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch item {
            case .goods(let goods):
                TradeGoodsArtwork(item: goods, accentColor: accentColor)
            case .cash(let amount):
                TradeCashOrbitArtwork(cashAmount: amount)
            }

            if let badgeTitle, clampedProminence > 0.70 {
                Text(badgeTitle)
                    .font(.system(size: 8.5 + CGFloat(clampedProminence) * 1.0, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.94), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(accentColor.opacity(0.20), lineWidth: 0.8)
                    }
                    .padding(4)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10 + CGFloat(clampedProminence), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10 + CGFloat(clampedProminence), style: .continuous)
                .strokeBorder(accentColor.opacity(0.44 + clampedProminence * 0.12), lineWidth: 1.2 + CGFloat(clampedProminence) * 0.45)
        }
        .shadow(color: accentColor.opacity(0.13 + clampedProminence * 0.07), radius: 6 + CGFloat(clampedProminence) * 3, y: 4)
    }
}

private struct TradeCashOrbitArtwork: View {
    var cashAmount: Int?

    var body: some View {
        LinearGradient(
            colors: [MegrumTheme.sky, MegrumTheme.lavender],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: 5) {
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 21, weight: .black))
                Text(cashText)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
            }
            .foregroundStyle(.white)
            .padding(6)
        }
    }

    private var cashText: String {
        cashAmount.map(TradeAmountFormatter.compactYen) ?? "定価"
    }
}
