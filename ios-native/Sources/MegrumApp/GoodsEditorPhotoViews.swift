import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsEditorInventoryPhotoSection: View {
    var draft: GoodsEditorDraft
    var photoError: String?
    var photoActionTitle: String
    var isItemReadOnly: Bool
    var onShowPhotoSource: () -> Void
    var onClearLocalPhoto: () -> Void

    var body: some View {
        GoodsEditorSectionContainer(title: "写真", systemImage: "camera") {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(GoodsEditorPhotoBackground.gradient)
                    .aspectRatio(draft.entryKind == .inventory ? 0.78 : 1.45, contentMode: .fit)
                    .overlay {
                        GoodsEditorPhotoPreview(draft: draft)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 16, y: 8)

                Button(action: onShowPhotoSource) {
                    Text(photoActionTitle)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.9), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isItemReadOnly)

                if draft.hasUnsavedLocalPhoto {
                    Button(role: .destructive, action: onClearLocalPhoto) {
                        Label("選択中の写真を外す", systemImage: "trash")
                            .font(.caption.weight(.black))
                    }
                    .buttonStyle(.bordered)
                    .disabled(isItemReadOnly)
                }

                Text("選んだ写真や撮影した写真は保存時にアップロードされます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)

                if draft.hasUnsavedLocalPhoto {
                    Label("保存に失敗しても、選択した写真はこの画面に残ります。", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.lavender)
                }

                if let photoError {
                    Text(photoError)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
