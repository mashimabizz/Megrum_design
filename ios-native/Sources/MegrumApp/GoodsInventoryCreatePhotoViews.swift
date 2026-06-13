import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct GoodsCreatePhotoSelectionGrid: View {
    var photos: [GoodsCreatePhotoDraft]
    var onRemovePhoto: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(photos.count)件 選択済")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                Text("保存時にアップロード")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(photos) { photo in
                    GoodsCreatePhotoTile(photo: photo) {
                        onRemovePhoto(photo.id)
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.48), lineWidth: 1)
        }
    }
}

struct GoodsCreatePhotoTile: View {
    var photo: GoodsCreatePhotoDraft
    var onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GoodsCreatePhotoPreview(data: photo.upload.data)
                .frame(height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Text("選択済み")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.34), in: Capsule())
                        .padding(8)
                }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.38), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(7)
            .accessibilityLabel("写真を削除")
        }
    }
}

struct GoodsCreatePhotoPreview: View {
    var data: Data

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
        #else
        GoodsCreatePhotoPreviewPlaceholder()
        #endif
    }
}

struct GoodsCreatePhotoPreviewPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(photoGradient)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
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
