import Foundation
import MegrumDesign
import SwiftUI

struct HomeCashAmountEntryCard: View {
    @Binding var amountText: String
    var suggestedAmount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSheetSectionTitle(
                systemName: "yensign.circle",
                title: "定価",
                trailing: suggestedAmount.map { TradeAmountFormatter.fixedPrice(amount: $0) }
            )

            HStack(spacing: 10) {
                Text("¥")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                TextField("金額を入力", text: $amountText)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .onChange(of: amountText) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        if digits != newValue {
                            amountText = digits
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.lavender.opacity(0.2), lineWidth: 1)
            }
        }
    }
}

struct HomeNoMatchingOfferGoodsPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("一致する候補はまだありません")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("この条件に合うあなたのグッズだけがここに表示されます。")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

enum HomeOfferGoodsOrdering {
    static func ordered(
        _ goods: [HomeMockGoods],
        preferredOfferGoodsID: UUID?
    ) -> [HomeMockGoods] {
        guard let preferredOfferGoodsID,
              let preferredIndex = goods.firstIndex(where: { $0.id == preferredOfferGoodsID })
        else {
            return goods
        }
        var orderedGoods = goods
        let preferredGoods = orderedGoods.remove(at: preferredIndex)
        orderedGoods.insert(preferredGoods, at: 0)
        return orderedGoods
    }
}
