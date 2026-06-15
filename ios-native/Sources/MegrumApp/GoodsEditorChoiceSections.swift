import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorMemberSelectionSection: View {
    var entryKind: GoodsEntryKind
    var members: [OshiCharacter]
    var isLoading: Bool
    var selectedGroupID: UUID?
    @Binding var selectedMemberID: UUID?
    var isItemReadOnly: Bool

    private var hint: String {
        entryKind == .wish ? "任意" : "任意・空 = 共通"
    }

    var body: some View {
        GoodsEditorSectionContainer(
            title: "メンバー / キャラ",
            systemImage: "person.crop.circle",
            hint: hint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                GoodsEditorFlowLayout(spacing: 9) {
                    GoodsEditorSelectionChip(
                        title: "指定なし",
                        isSelected: selectedMemberID == nil,
                        isDisabled: isItemReadOnly
                    ) {
                        selectedMemberID = nil
                    }
                    ForEach(members) { member in
                        GoodsEditorSelectionChip(
                            title: member.name,
                            isSelected: selectedMemberID == member.id,
                            isDisabled: isItemReadOnly || selectedGroupID == nil
                        ) {
                            selectedMemberID = member.id
                        }
                    }
                }

                Text("指定なしでも保存できます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

struct GoodsEditorGoodsTypeSelectionSection: View {
    var goodsTypes: [GoodsType]
    var isLoading: Bool
    @Binding var selectedGoodsTypeID: UUID?
    var isItemReadOnly: Bool

    var body: some View {
        GoodsEditorSectionContainer(title: "グッズ種別", systemImage: "square.grid.2x2", required: true) {
            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                GoodsEditorFlowLayout(spacing: 9) {
                    ForEach(goodsTypes) { goodsType in
                        GoodsEditorSelectionChip(
                            title: goodsType.name,
                            isSelected: selectedGoodsTypeID == goodsType.id,
                            isDisabled: isItemReadOnly
                        ) {
                            selectedGoodsTypeID = goodsType.id
                        }
                    }
                }
            }
        }
    }
}
