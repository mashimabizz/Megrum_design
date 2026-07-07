import Foundation
import MegrumDesign
import SwiftUI

struct HomeCashAmountEntryCard: View {
    @Binding var amountText: String
    var suggestedAmount: Int?
    /// 相手の指定（「定価」または「〇〇円」）。候補シート再設計で入力欄の下に表示。iter1226.375。
    var partnerDesignationText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSheetSectionTitle(
                systemName: "yensign.circle",
                title: "渡す金額を入力",
                trailing: partnerDesignationText == nil
                    ? suggestedAmount.map { TradeAmountFormatter.fixedPrice(amount: $0) }
                    : nil
            )

            HStack(spacing: 10) {
                Text("¥")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                amountField
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.lavender.opacity(0.2), lineWidth: 1)
            }

            if let partnerDesignationText {
                Text(partnerDesignationText)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    @ViewBuilder
    private var amountField: some View {
        let field = TextField("金額を入力", text: $amountText)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .onChange(of: amountText) { _, newValue in
                normalizeAmountText(newValue)
            }
            .onAppear {
                normalizeAmountText(amountText)
            }

        #if os(iOS)
        field.keyboardType(.numberPad)
        #else
        field
        #endif
    }

    private func normalizeAmountText(_ text: String) {
        let normalizedText = TradeAmountFormatter.cashInputText(from: text)
        guard normalizedText != amountText else {
            return
        }
        amountText = normalizedText
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
