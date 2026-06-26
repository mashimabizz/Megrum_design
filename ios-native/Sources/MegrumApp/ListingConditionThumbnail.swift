import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct ListingConditionThumbnail: View {
    var imageName: String

    private var imageURL: URL? {
        Bundle.module.url(forResource: imageName, withExtension: "png", subdirectory: "TestGoodsImages")
            ?? URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/TestGoodsImages/\(imageName).png")
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(MegrumTheme.lavender.opacity(0.12))
            .overlay {
                ListingConditionThumbnailImageLayer(imageURL: imageURL)
            }
            .frame(
                width: ListingConditionDesignMetrics.optionThumbnailSize,
                height: ListingConditionDesignMetrics.optionThumbnailSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.78), lineWidth: 1)
            }
    }
}

private struct ListingConditionThumbnailImageLayer: View {
    var imageURL: URL?

    var body: some View {
        #if canImport(UIKit)
        if let imageURL,
           let data = try? Data(contentsOf: imageURL),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ListingConditionThumbnailPlaceholder()
        }
        #else
        ListingConditionThumbnailPlaceholder()
        #endif
    }
}

private struct ListingConditionThumbnailPlaceholder: View {
    var body: some View {
        LinearGradient(
            colors: [
                MegrumTheme.lavender.opacity(0.42),
                MegrumTheme.pink.opacity(0.32)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
#endif
