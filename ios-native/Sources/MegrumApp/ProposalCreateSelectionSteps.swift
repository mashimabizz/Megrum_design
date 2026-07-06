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
                    ProposalSelectableGoodsGrid(
                        items: filteredGoods,
                        selectedGoodsIDs: selectedGoodsIDs,
                        accessibilityHint: "を出すものに選択",
                        onToggleGoods: onToggleGoods
                    )
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

                ProposalSelectableGoodsGrid(
                    items: filteredGoods,
                    selectedGoodsIDs: selectedGoodsIDs,
                    accessibilityHint: "を受け取るものに選択",
                    onToggleGoods: onToggleGoods
                )

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

/// 個別募集の作成画面と同じ4列の画像グリッド（iter1226.346）。
private struct ProposalSelectableGoodsGrid: View {
    var items: [GoodsItem]
    var selectedGoodsIDs: Set<UUID>
    var accessibilityHint: String
    var onToggleGoods: (UUID) -> Void

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 12) {
            ForEach(items) { item in
                Button {
                    onToggleGoods(item.id)
                } label: {
                    ListingSelectableImageTile(
                        imageURL: item.imageURL,
                        title: item.title,
                        isSelected: selectedGoodsIDs.contains(item.id)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title)\(accessibilityHint)")
                .accessibilityAddTraits(selectedGoodsIDs.contains(item.id) ? .isSelected : [])
            }
        }
    }
}
