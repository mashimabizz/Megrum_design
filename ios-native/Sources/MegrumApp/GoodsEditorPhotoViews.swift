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
                    .fill(photoGradient)
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

    private var photoGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

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
                        .fill(photoGradient)
                        .frame(width: 88, height: 88)
                        .overlay {
                            GoodsEditorPhotoPreview(draft: draft)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(titlePreview.isEmpty ? "Wish画像" : titlePreview)
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

    private var photoGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
