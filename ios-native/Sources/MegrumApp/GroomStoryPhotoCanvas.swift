import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GroomStoryPhotoCanvas: View {
    var photoData: Data

    var body: some View {
        ZStack {
            #if canImport(UIKit)
            if let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 34)
                    .saturation(0.92)
                    .scaleEffect(1.10)
                    .overlay(.black.opacity(0.20))

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                GroomStoryPhotoFallback()
            }
            #else
            GroomStoryPhotoFallback()
            #endif
        }
        .clipped()
    }
}

struct GroomStoryOverlayText: View {
    var overlay: GroomStoryTextOverlay
    var canvasSize: CGSize

    var body: some View {
        Text(overlay.text)
            .font(
                .system(
                    size: baseFontSize * overlay.scale,
                    weight: .regular,
                    design: .rounded
                )
            )
            .foregroundStyle(overlay.color.color)
            .shadow(color: overlay.color.shadowColor, radius: 4, x: 0, y: 2)
            .multilineTextAlignment(.leading)
            .lineLimit(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: min(canvasSize.width * 0.84, canvasSize.width - 38), alignment: .leading)
    }

    private var baseFontSize: CGFloat {
        min(max(canvasSize.width * 0.105, 30), 108)
    }
}

private struct GroomStoryPhotoFallback: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.52, green: 0.30, blue: 0.22))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white.opacity(0.80))
            }
    }
}
