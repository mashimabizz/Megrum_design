import MegrumDesign
import SwiftUI

struct GoodsEditorWishPhotoSection: View {
    var draft: GoodsEditorDraft
    var photoError: String?
    var photoActionTitle: String
    var titlePreview: String
    var wishImageHint: String
    var isItemReadOnly: Bool
    var isWishPhotoRemovalLocked: Bool
    var onShowPhotoSource: () -> Void
    var onRemoveWishPhoto: () -> Void

    var body: some View {
        GoodsEditorSectionContainer(title: "画像", systemImage: "photo", hint: wishImageHint) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(GoodsEditorPhotoBackground.gradient)
                        .frame(width: 88, height: 88)
                        .overlay {
                            GoodsEditorPhotoPreview(draft: draft)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(titlePreview.isEmpty ? "ほしいもの画像" : titlePreview)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(draft.hasDisplayPhoto ? "画像を登録しました" : "未紐付け")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Button(action: onShowPhotoSource) {
                                Text(photoActionTitle)
                            }
                            .buttonStyle(.bordered)
                            .tint(MegrumTheme.lavender)
                            .disabled(isItemReadOnly)

                            if draft.hasDisplayPhoto {
                                Button(role: .destructive, action: onRemoveWishPhoto) {
                                    Text("削除")
                                }
                                .buttonStyle(.bordered)
                                .disabled(isItemReadOnly || isWishPhotoRemovalLocked)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isWishPhotoRemovalLocked && draft.hasDisplayPhoto {
                    Text("個別募集で使用中のため削除できません。差し替えは可能です。")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
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
