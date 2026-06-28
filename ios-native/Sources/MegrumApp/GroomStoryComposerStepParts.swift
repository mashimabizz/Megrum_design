import Foundation
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(Photos)
import Photos
#endif
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
    var onSelectPhotoData: (Data, String) -> Void
    @State private var recentAssets: [GroomPhotoLibraryAsset] = []
    @State private var authorizationStatus: GroomPhotoLibraryAuthorization = .unknown

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("最近の項目")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(
                columns: GroomPhotoActionGridMetrics.columns,
                spacing: GroomPhotoActionGridMetrics.spacing
            ) {
                Button(action: onOpenCamera) {
                    GroomComposerCameraTile(isLoading: isPreparingPhoto)
                }
                .buttonStyle(.plain)
                .disabled(isPreparingPhoto || isCreating)
                .opacity(canUseCamera ? 1 : 0.48)

                #if canImport(UIKit) && canImport(Photos)
                ForEach(recentAssets) { asset in
                    Button {
                        loadPhotoData(for: asset)
                    } label: {
                        GroomPhotoLibraryThumbnail(asset: asset)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPreparingPhoto || isCreating)
                }
                #endif
            }

            if authorizationStatus == .denied {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("アルバムから選ぶ", systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            await loadRecentAssets()
        }
    }

    @MainActor
    private func loadRecentAssets() async {
        #if canImport(UIKit) && canImport(Photos)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            authorizationStatus = .authorized
            recentAssets = GroomPhotoLibraryAsset.fetchRecent(limit: 35)
        case .notDetermined:
            authorizationStatus = .unknown
            let requested = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    continuation.resume(returning: status)
                }
            }
            if requested == .authorized || requested == .limited {
                authorizationStatus = .authorized
                recentAssets = GroomPhotoLibraryAsset.fetchRecent(limit: 35)
            } else {
                authorizationStatus = .denied
                recentAssets = []
            }
        default:
            authorizationStatus = .denied
            recentAssets = []
        }
        #else
        authorizationStatus = .denied
        #endif
    }

    private func loadPhotoData(for asset: GroomPhotoLibraryAsset) {
        #if canImport(UIKit) && canImport(Photos)
        guard let phAsset = asset.phAsset else {
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: options) { data, typeIdentifier, _, _ in
            guard let data else {
                return
            }
            Task { @MainActor in
                onSelectPhotoData(data, GroomPhotoLibraryAsset.contentType(for: typeIdentifier))
            }
        }
        #endif
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
