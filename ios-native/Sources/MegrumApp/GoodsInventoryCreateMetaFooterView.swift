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

    @State private var presentationState = GoodsInventoryCreateMetaFooterPresentationState()

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if allowsMemberSelection {
                    footerButton(
                        title: "メンバー登録",
                        systemImage: "person.crop.circle.badge.plus",
                        action: { presentationState.showMemberDialog() }
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
        // iter1226.436：confirmationDialog はメンバーが多いと下の2〜3件が初期表示されない
        // OS側の描画バグがあるため、標準のシート（List）で全件確実に表示する。
        .sheet(isPresented: $presentationState.isShowingMemberDialog) {
            GoodsCreateMemberAssignSheet(
                memberOptions: memberOptions,
                selectedCount: selectedCount,
                onAssignMember: onAssignMember
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var saveTitle: String {
        presentationState.saveTitle(selectedCount: selectedCount, totalCount: totalCount)
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
