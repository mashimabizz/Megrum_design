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

    @State private var showsTypeSelectSheet = false

    private var selectedGoodsTypeName: String? {
        selectedGoodsTypeID.flatMap { id in
            goodsTypes.first { $0.id == id }?.name
        }
    }

    var body: some View {
        GoodsEditorSectionContainer(title: "グッズ種別", systemImage: "square.grid.2x2", required: true) {
            Button {
                showsTypeSelectSheet = true
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("グッズ種別")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                        if isLoading {
                            Text("読み込み中")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer(minLength: 12)
                    Text(selectedGoodsTypeName ?? "選択")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(selectedGoodsTypeName == nil ? MegrumTheme.muted : MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isItemReadOnly || isLoading)
        }
        .sheet(isPresented: $showsTypeSelectSheet) {
            GoodsTypeSelectSheet(
                goodsTypes: goodsTypes,
                selectedGoodsTypeID: selectedGoodsTypeID,
                onSelect: { goodsType in
                    selectedGoodsTypeID = goodsType.id
                    showsTypeSelectSheet = false
                },
                onClose: { showsTypeSelectSheet = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
