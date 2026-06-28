import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum MeguriCreationLocationPreview {
    case pin
    case groom(imageData: Data?, caption: String?)
    case board(title: String, summary: String, hasThumbnail: Bool)
}

struct CurrentLocationDot: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 24, height: 24)
                .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 8, y: 3)
            Circle()
                .fill(MegrumTheme.sky)
                .frame(width: 14, height: 14)
            Circle()
                .stroke(.white.opacity(0.9), lineWidth: 2)
                .frame(width: 34, height: 34)
                .background(MegrumTheme.sky.opacity(0.16), in: Circle())
        }
    }
}

struct SelectedCreationLocationAnnotation: View {
    var preview: MeguriCreationLocationPreview

    var body: some View {
        VStack(spacing: 0) {
            previewBubble

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white, MegrumTheme.lavender)
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 10, y: 5)
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.28))
                .frame(width: 14, height: 6)
                .blur(radius: 1)
        }
    }

    @ViewBuilder
    private var previewBubble: some View {
        switch preview {
        case .pin:
            EmptyView()
        case let .groom(imageData, caption):
            GroomCreationMapPreview(imageData: imageData, caption: caption)
                .padding(.bottom, -2)
        case let .board(title, summary, hasThumbnail):
            BoardCreationMapPreview(title: title, summary: summary, hasThumbnail: hasThumbnail)
                .padding(.bottom, -2)
        }
    }
}

private struct GroomCreationMapPreview: View {
    var imageData: Data?
    var caption: String?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 58, height: 58)
                    .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 12, y: 5)

                #if canImport(UIKit)
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else {
                    groomFallback
                }
                #else
                groomFallback
                #endif
            }

            if let caption = caption?.nilIfBlank {
                Text(caption)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: 96)
                    .frame(height: 22)
                    .background(.white.opacity(0.94), in: Capsule())
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 8, y: 3)
            }
        }
    }

    private var groomFallback: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 52, height: 52)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}

private struct BoardCreationMapPreview: View {
    var title: String
    var summary: String
    var hasThumbnail: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(MegrumTheme.lavender.opacity(0.14))
                Image(systemName: hasThumbnail ? "photo.fill" : "text.bubble.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.nilIfBlank ?? "チャットルーム")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary.nilIfBlank ?? "現地の話題")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(width: 150, alignment: .leading)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 5)
    }
}
