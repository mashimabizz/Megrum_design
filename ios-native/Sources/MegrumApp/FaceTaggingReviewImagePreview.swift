import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct FaceTaggingImagePreview: View {
    var imageData: Data

    private var imageSize: CGSize? {
        faceReviewPlatformImageSize(from: imageData)
    }

    var body: some View {
        GeometryReader { proxy in
            let displayRect = faceReviewFittedImageRect(
                imageSize: imageSize ?? CGSize(width: 1, height: 1),
                containerSize: proxy.size
            )

            ZStack {
                Color.black.opacity(0.06)

                FaceTaggingSourceImage(data: imageData)
                    .frame(width: displayRect.width, height: displayRect.height)
                    .position(x: displayRect.midX, y: displayRect.midY)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
    }
}

private struct FaceTaggingSourceImage: View {
    var data: Data

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            FaceTaggingImagePlaceholder()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            FaceTaggingImagePlaceholder()
        }
        #else
        FaceTaggingImagePlaceholder()
        #endif
    }
}

private struct FaceTaggingImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.white)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
    }
}

private func faceReviewPlatformImageSize(from data: Data) -> CGSize? {
    #if canImport(UIKit)
    UIImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #elseif canImport(AppKit)
    NSImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #else
    nil
    #endif
}

private func faceReviewFittedImageRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
        return CGRect(origin: .zero, size: containerSize)
    }
    let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return CGRect(
        x: (containerSize.width - size.width) / 2,
        y: (containerSize.height - size.height) / 2,
        width: size.width,
        height: size.height
    )
}
