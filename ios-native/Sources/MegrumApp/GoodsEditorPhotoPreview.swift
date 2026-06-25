import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct GoodsEditorPhotoPreview: View {
    var draft: GoodsEditorDraft

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if let localPhotoData = draft.localPhotoData {
            localPhotoPreview(data: localPhotoData)
        } else if let existingImageURL = draft.existingImageURL {
            AsyncImage(url: existingImageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                switch phase {
                case .empty:
                    photoPlaceholder(status: "写真を読み込み中", showsProgress: true)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(alignment: .bottomLeading) {
                            PhotoStatusBadge(text: draft.photoStatusText)
                                .padding(12)
                        }
                case .failure:
                    photoPlaceholder(status: "保存済み写真を表示できません")
                @unknown default:
                    photoPlaceholder(status: draft.photoStatusText)
                }
            }
        } else {
            photoPlaceholder(status: draft.photoStatusText)
        }
    }

    @ViewBuilder
    private func localPhotoPreview(data: Data) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .overlay(alignment: .bottomLeading) {
                    PhotoStatusBadge(text: draft.photoStatusText)
                        .padding(12)
                }
        } else {
            photoPlaceholder(status: draft.photoStatusText)
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .overlay(alignment: .bottomLeading) {
                    PhotoStatusBadge(text: draft.photoStatusText)
                        .padding(12)
                }
        } else {
            photoPlaceholder(status: draft.photoStatusText)
        }
        #else
        photoPlaceholder(status: draft.photoStatusText)
        #endif
    }

    private func photoPlaceholder(status: String, showsProgress: Bool = false) -> some View {
        VStack(spacing: 10) {
            if showsProgress {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.white)
            } else {
                Image(systemName: draft.hasDisplayPhoto ? "photo.fill.on.rectangle.fill" : "photo")
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
