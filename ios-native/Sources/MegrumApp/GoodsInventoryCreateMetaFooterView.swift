import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsInventoryCreateMetaFooterView: View {
    var selectedCount: Int
    var totalCount: Int
    var memberOptions: [OshiCharacter]
    var allowsMemberSelection: Bool
    var canSaveMetas: Bool
    var isCreatingGoodsEntry: Bool
    var onAssignMember: (UUID?) -> Void
    var onShowTagAssignment: () -> Void
    var onBack: () -> Void
    var onSave: () -> Void

    @State private var isShowingMemberDialog = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if allowsMemberSelection {
                    footerButton(
                        title: "メンバー登録",
                        systemImage: "person.crop.circle.badge.plus",
                        action: { isShowingMemberDialog = true }
                    )
                    .disabled(selectedCount == 0 || memberOptions.isEmpty || isCreatingGoodsEntry)
                }

                footerButton(
                    title: "シリーズ登録",
                    systemImage: "tag",
                    action: onShowTagAssignment
                )
                .disabled(selectedCount == 0 || isCreatingGoodsEntry)
            }

            HStack(spacing: 10) {
                GoodsCreateSecondaryButton(
                    title: "戻る",
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    action: onBack
                )
                GoodsCreatePrimaryButton(
                    title: saveTitle,
                    isDisabled: !canSaveMetas,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    showsProgress: true,
                    action: onSave
                )
            }
        }
        .confirmationDialog(
            "メンバーを登録",
            isPresented: $isShowingMemberDialog,
            titleVisibility: .visible
        ) {
            ForEach(memberOptions) { member in
                Button(member.name) {
                    onAssignMember(member.id)
                }
            }
            Button("メンバー未設定に戻す", role: .destructive) {
                onAssignMember(nil)
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(selectedCount)件の画像に同じメンバーを割り当てます。")
        }
    }

    private var saveTitle: String {
        if selectedCount == 0, totalCount > 0 {
            return "画像を選択してください"
        }
        return "\(totalCount)件まとめて登録"
    }

    private func footerButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
