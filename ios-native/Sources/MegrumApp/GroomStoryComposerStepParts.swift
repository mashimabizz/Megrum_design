import Foundation
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GroomStoryComposerStepHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GroomStoryPhotoActionGrid: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var cameraSubtitle: String
    var onOpenCamera: () -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            Button(action: onOpenCamera) {
                GroomComposerActionTile(
                    title: "カメラで撮る",
                    subtitle: cameraSubtitle,
                    systemImage: "camera.fill",
                    isLoading: isPreparingPhoto
                )
            }
            .buttonStyle(.plain)
            .disabled(isPreparingPhoto || isCreating)
            .opacity(canUseCamera ? 1 : 0.48)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                GroomComposerActionTile(
                    title: "写真を選ぶ",
                    subtitle: "写真が決まったら場所選択へ",
                    systemImage: "photo.on.rectangle.angled",
                    isLoading: isPreparingPhoto
                )
            }
            .buttonStyle(.plain)
            .disabled(isPreparingPhoto || isCreating)
        }
    }
}

struct GroomStoryCaptionField: View {
    @Binding var captionText: String

    var body: some View {
        TextField("写真に添えるひとこと", text: $captionText, axis: .vertical)
            .lineLimit(1...3)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(14)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(MegrumTheme.ink)
    }
}

struct GroomStoryPublishButton: View {
    var isCreating: Bool
    var canCreateAtSelectedLocation: Bool
    var onPublish: () -> Void

    var body: some View {
        Button(action: onPublish) {
            Group {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("この場所に投稿する")
                }
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(MegrumTheme.lavender, in: Capsule())
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!canCreateAtSelectedLocation || isCreating)
        .opacity(canCreateAtSelectedLocation && !isCreating ? 1 : 0.48)
    }
}

struct GroomStoryResetPhotoButton: View {
    var onReset: () -> Void

    var body: some View {
        Button("写真を選び直す", systemImage: "arrow.counterclockwise", action: onReset)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .buttonStyle(.plain)
    }
}

struct GroomDraftPhotoPreview: View {
    var photoData: Data
    var caption: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            #if canImport(UIKit)
            if let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                photoFallback
            }
            #else
            photoFallback
            #endif

            if let caption {
                Text(caption)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.36), in: Capsule())
                    .padding(14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var photoFallback: some View {
        Rectangle()
            .fill(MegrumTheme.lavender.opacity(0.20))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

private struct GroomComposerActionTile: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 128)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
        }
    }
}
