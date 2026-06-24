import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalGiveGoodsStep: View {
    var selectableGoods: [GoodsItem]
    var filteredGoods: [GoodsItem]
    var groupChoices: [ProposalFilterChoice]
    var goodsTypeChoices: [ProposalFilterChoice]
    var selectedGoodsIDs: Set<UUID>
    var cashReferenceRows: [ProposalCashReferenceRow] = []
    @Binding var selectionMode: ProposalSideSelectionMode
    @Binding var cashAmountText: String
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    var onToggleGoods: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ProposalCandidateListMetrics.paneSpacing) {
            ProposalSideSelectionModeTabs(selection: $selectionMode)

            if selectionMode == .cash {
                ProposalCashAmountEntry(
                    title: "出す金額",
                    placeholder: "入力…",
                    amountText: $cashAmountText,
                    referenceRows: cashReferenceRows
                )
            } else {
                ProposalGoodsFilterBar(
                    groupChoices: groupChoices,
                    goodsTypeChoices: goodsTypeChoices,
                    selectedGroupID: $selectedGroupID,
                    selectedGoodsTypeID: $selectedGoodsTypeID
                )

                if selectableGoods.isEmpty {
                    ContentUnavailableView(
                        "マイグッズがありません",
                        systemImage: "tray",
                        description: Text("マイグッズを登録すると、ここから出すものを選べます。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else if filteredGoods.isEmpty {
                    ContentUnavailableView(
                        "条件に合うマイグッズがありません",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("推しや種別の条件を変えてください。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    VStack(spacing: ProposalCandidateListMetrics.spacing) {
                        ForEach(filteredGoods) { item in
                            ProposalSelectableGoodsRow(
                                item: item,
                                isSelected: selectedGoodsIDs.contains(item.id),
                                hintText: "相手がほしいものかも？"
                            ) {
                                onToggleGoods(item.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ProposalReceiveGoodsStep: View {
    var filteredGoods: [GoodsItem]
    var groupChoices: [ProposalFilterChoice]
    var goodsTypeChoices: [ProposalFilterChoice]
    var selectedGoodsIDs: Set<UUID>
    var cashReferenceRows: [ProposalCashReferenceRow] = []
    @Binding var selectionMode: ProposalSideSelectionMode
    @Binding var cashAmountText: String
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    var onToggleGoods: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ProposalCandidateListMetrics.paneSpacing) {
            ProposalSideSelectionModeTabs(selection: $selectionMode)

            if selectionMode == .cash {
                ProposalCashAmountEntry(
                    title: "受け取る金額",
                    placeholder: "入力…",
                    amountText: $cashAmountText,
                    referenceRows: cashReferenceRows
                )
            } else {
                ProposalGoodsFilterBar(
                    groupChoices: groupChoices,
                    goodsTypeChoices: goodsTypeChoices,
                    selectedGroupID: $selectedGroupID,
                    selectedGoodsTypeID: $selectedGoodsTypeID
                )

                VStack(spacing: ProposalCandidateListMetrics.spacing) {
                    ForEach(filteredGoods) { item in
                        ProposalSelectableGoodsRow(
                            item: item,
                            isSelected: selectedGoodsIDs.contains(item.id),
                            hintText: "私がほしいものかも？"
                        ) {
                            onToggleGoods(item.id)
                        }
                    }
                }

                if filteredGoods.isEmpty {
                    ContentUnavailableView(
                        "条件に合う候補がありません",
                        systemImage: "sparkles",
                        description: Text("推しや種別の条件を変えてください。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }
}

private struct ProposalSideSelectionModeTabs: View {
    @Binding var selection: ProposalSideSelectionMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProposalSideSelectionMode.allCases) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.16)) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(selection == mode ? .white : MegrumTheme.ink.opacity(0.58))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            selection == mode ? MegrumTheme.lavender : Color.clear,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
        }
        .padding(3)
        .background(MegrumTheme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.68), lineWidth: 1)
        }
    }
}

private struct ProposalCashAmountEntry: View {
    var title: String
    var placeholder: String
    @Binding var amountText: String
    var referenceRows: [ProposalCashReferenceRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 10) {
                Text("¥")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                amountField
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
            }

            if !referenceRows.isEmpty {
                VStack(spacing: 7) {
                    ForEach(referenceRows) { row in
                        HStack(spacing: 10) {
                            Text(row.label)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                                .frame(width: 74, alignment: .leading)
                            Text(row.value)
                                .font(.system(size: 12.5, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onChange(of: amountText) { _, newValue in
            let normalized = TradeAmountFormatter.cashInputText(from: newValue)
            if normalized != newValue {
                amountText = normalized
            }
        }
    }

    @ViewBuilder
    private var amountField: some View {
        let field = TextField(placeholder, text: $amountText)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(.trailing)
        #if os(iOS)
        field.keyboardType(.numberPad)
        #else
        field
        #endif
    }
}
