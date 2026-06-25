import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct GoodsEditorPhotoPreviewContent: View {
    var localPhotoData: Data?
    var existingImageURL: URL?
    var photoStatusText: String
    var hasDisplayPhoto: Bool

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if let localPhotoData {
            localPhotoPreview(data: localPhotoData)
        } else if let existingImageURL {
            AsyncImage(url: existingImageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                switch phase {
                case .empty:
                    GoodsEditorPhotoPlaceholder(
                        status: "写真を読み込み中",
                        showsProgress: true,
                        hasDisplayPhoto: hasDisplayPhoto
                    )
                case let .success(image):
                    previewImage(image)
                case .failure:
                    GoodsEditorPhotoPlaceholder(
                        status: "保存済み写真を表示できません",
                        hasDisplayPhoto: hasDisplayPhoto
                    )
                @unknown default:
                    GoodsEditorPhotoPlaceholder(
                        status: photoStatusText,
                        hasDisplayPhoto: hasDisplayPhoto
                    )
                }
            }
        } else {
            GoodsEditorPhotoPlaceholder(
                status: photoStatusText,
                hasDisplayPhoto: hasDisplayPhoto
            )
        }
    }

    @ViewBuilder
    private func localPhotoPreview(data: Data) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            previewImage(Image(uiImage: image))
        } else {
            GoodsEditorPhotoPlaceholder(
                status: photoStatusText,
                hasDisplayPhoto: hasDisplayPhoto
            )
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            previewImage(Image(nsImage: image))
        } else {
            GoodsEditorPhotoPlaceholder(
                status: photoStatusText,
                hasDisplayPhoto: hasDisplayPhoto
            )
        }
        #else
        GoodsEditorPhotoPlaceholder(
            status: photoStatusText,
            hasDisplayPhoto: hasDisplayPhoto
        )
        #endif
    }

    private func previewImage(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .overlay(alignment: .bottomLeading) {
                PhotoStatusBadge(text: photoStatusText)
                    .padding(12)
            }
    }
}

struct GoodsEditorPhotoPlaceholder: View {
    var status: String
    var showsProgress = false
    var hasDisplayPhoto: Bool

    var body: some View {
        VStack(spacing: 10) {
            if showsProgress {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.white)
            } else {
                Image(systemName: hasDisplayPhoto ? "photo.fill.on.rectangle.fill" : "photo")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            Text(status)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
