import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum GroomStoryExportRenderer {
    enum RenderError: Error {
        case imageUnavailable
        case jpegUnavailable
    }

    static let canvasSize = CGSize(width: 1080, height: 1920)
    static let maxJPEGBytes = 8_800_000

    private static let jpegCompressionQualities: [CGFloat] = [
        0.82,
        0.74,
        0.66,
        0.58,
        0.50,
        0.42,
    ]

    @MainActor
    static func renderedJPEGData(
        photoData: Data,
        textOverlays: [GroomStoryTextOverlay]
    ) throws -> Data {
        #if canImport(UIKit)
        let view = GroomStoryExportView(
            photoData: photoData,
            textOverlays: textOverlays
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(
            width: canvasSize.width,
            height: canvasSize.height
        )
        guard let image = renderer.uiImage else {
            throw RenderError.imageUnavailable
        }
        guard let jpegData = jpegData(from: image) else {
            throw RenderError.jpegUnavailable
        }
        return jpegData
        #else
        return photoData
        #endif
    }

    #if canImport(UIKit)
    private static func jpegData(from image: UIImage) -> Data? {
        var fallbackData: Data?
        for quality in jpegCompressionQualities {
            guard let data = image.jpegData(compressionQuality: quality) else {
                continue
            }
            fallbackData = data
            if data.count <= maxJPEGBytes {
                return data
            }
        }
        return fallbackData
    }
    #endif
}

private struct GroomStoryExportView: View {
    var photoData: Data
    var textOverlays: [GroomStoryTextOverlay]

    var body: some View {
        ZStack {
            GroomStoryPhotoCanvas(photoData: photoData)

            ForEach(textOverlays) { overlay in
                GroomStoryOverlayText(
                    overlay: overlay,
                    canvasSize: GroomStoryExportRenderer.canvasSize
                )
                .position(
                    x: overlay.normalizedPosition.x * GroomStoryExportRenderer.canvasSize.width,
                    y: overlay.normalizedPosition.y * GroomStoryExportRenderer.canvasSize.height
                )
            }
        }
        .frame(
            width: GroomStoryExportRenderer.canvasSize.width,
            height: GroomStoryExportRenderer.canvasSize.height
        )
        .clipped()
    }
}
