import Foundation
import SwiftUI
#if canImport(Photos)
import Photos
#endif
#if canImport(UIKit)
import UIKit
#endif

enum GroomPhotoActionGridMetrics {
    static let spacing: CGFloat = 4
    static let columns = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: spacing),
        count: 3
    )
}

enum GroomPhotoLibraryAuthorization {
    case unknown
    case authorized
    case denied
}

struct GroomPhotoLibraryAsset: Identifiable, Equatable {
    var id: String

    #if canImport(Photos)
    var phAsset: PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }

    /// `limit <= 0` で全件取得。サムネイルは LazyVGrid で遅延読込されるため、
    /// 識別子の全件列挙だけなら大規模ライブラリでも軽い。
    static func fetchRecent(limit: Int = 0) -> [GroomPhotoLibraryAsset] {
        let options = PHFetchOptions()
        if limit > 0 {
            options.fetchLimit = limit
        }
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [GroomPhotoLibraryAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(GroomPhotoLibraryAsset(id: asset.localIdentifier))
        }
        return assets
    }

    static func contentType(for typeIdentifier: String?) -> String {
        let normalized = typeIdentifier?.lowercased() ?? ""
        if normalized.contains("png") {
            return "image/png"
        }
        if normalized.contains("webp") {
            return "image/webp"
        }
        return "image/jpeg"
    }
    #endif
}

#if canImport(UIKit) && canImport(Photos)
struct GroomPhotoLibraryThumbnail: View {
    var asset: GroomPhotoLibraryAsset
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(.white.opacity(0.08))

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .task(id: asset.id) {
            await loadThumbnail()
        }
    }

    @MainActor
    private func loadThumbnail() async {
        guard let phAsset = asset.phAsset else {
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: phAsset,
            targetSize: CGSize(width: 240, height: 240),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            Task { @MainActor in
                self.image = image
            }
        }
    }
}
#endif

struct GroomComposerCameraTile: View {
    var isLoading: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white.opacity(0.12))

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityLabel("カメラで撮る")
    }
}
