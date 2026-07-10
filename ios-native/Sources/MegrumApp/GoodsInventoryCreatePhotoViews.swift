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
    var onCropPhoto: (UUID) -> Void
    var onAddPhoto: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("追加した写真")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 8)
                Text("\(photos.count)件")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(photos) { photo in
                        GoodsCreatePhotoTile(
                            photo: photo,
                            onOpen: { onCropPhoto(photo.id) },
                            onRemove: { onRemovePhoto(photo.id) }
                        )
                    }
                    if let onAddPhoto {
                        GoodsCreatePhotoAddTile(action: onAddPhoto)
                    }
                }
            }
            .scrollIndicators(.hidden)
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
    var onOpen: () -> Void
    var onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                GoodsCreatePhotoPreview(data: photo.upload.data)
                    .frame(width: 118, height: 118)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        // タップ＝再トリミングできることを明示するバッジ
                        Image(systemName: "crop")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 24, height: 24)
                            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: .black.opacity(0.16), radius: 3, y: 1)
                            .padding(6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("トリミングを調整")

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
        .frame(width: 118, height: 118)
    }
}

struct GoodsCreatePhotoAddTile: View {
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 118, height: 118)
                .background(MegrumTheme.lavender.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            MegrumTheme.lavender.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.4, dash: [6, 4])
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("写真を追加")
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
