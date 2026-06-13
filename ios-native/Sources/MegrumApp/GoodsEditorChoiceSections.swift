import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorGroupSelectionSection: View {
    var title: String
    var required: Bool
    var groups: [OshiGroup]
    var isLoading: Bool
    @Binding var selectedGroupID: UUID?
    var isItemReadOnly: Bool

    var body: some View {
        GoodsEditorSectionContainer(title: title, systemImage: "person.2", required: required) {
            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                if groups.isEmpty && !isLoading {
                    Text("推し設定に登録済みのグループがありません")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
                } else {
                    GoodsEditorFlowLayout(spacing: 9) {
                        ForEach(groups) { group in
                            GoodsEditorSelectionChip(
                                title: group.name,
                                isSelected: selectedGroupID == group.id,
                                isDisabled: isItemReadOnly
                            ) {
                                selectedGroupID = group.id
                            }
                        }
                    }
                }
            }
        }
    }
}

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
