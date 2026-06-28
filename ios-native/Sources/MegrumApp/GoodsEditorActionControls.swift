import MegrumDesign
import SwiftUI

struct GoodsEditorCloseButton: View {
    var onClose: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(onClose)
        } label: {
            Text("戻る")
                .font(.headline.weight(.black))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
    }
}

struct GoodsEditorSaveButton: View {
    var title: String
    var isSaving: Bool
    var canSave: Bool
    var onSave: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(onSave)
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .tint(MegrumTheme.lavender)
        .disabled(!canSave)
    }
}

struct GoodsEditorDeleteButton: View {
    var hasExistingItem: Bool
    var isMutating: Bool
    var onConfirmDelete: () -> Void

    var body: some View {
        Button(role: .destructive) {
            MegrumHaptics.performButtonTap(onConfirmDelete)
        } label: {
            HStack(spacing: 8) {
                if isMutating {
                    ProgressView()
                }
                Text("このマイグッズを削除")
                    .font(.headline.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.bordered)
        .disabled(!hasExistingItem || isMutating)
    }
}
