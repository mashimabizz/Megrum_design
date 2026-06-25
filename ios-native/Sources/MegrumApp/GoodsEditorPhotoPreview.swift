import SwiftUI

struct GoodsEditorPhotoPreview: View {
    var draft: GoodsEditorDraft

    var body: some View {
        GoodsEditorPhotoPreviewContent(
            localPhotoData: draft.localPhotoData,
            existingImageURL: draft.existingImageURL,
            photoStatusText: draft.photoStatusText,
            hasDisplayPhoto: draft.hasDisplayPhoto
        )
    }
}

struct PhotoStatusBadge: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(.black.opacity(0.34), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
    }
}
