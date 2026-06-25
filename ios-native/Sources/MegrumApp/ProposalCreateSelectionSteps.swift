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
