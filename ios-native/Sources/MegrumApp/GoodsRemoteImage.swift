import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GoodsRemoteImage: View {
    var url: URL
    var cornerRadius: CGFloat
    var placeholderIconSize: CGFloat
    @State private var loadState: GoodsRemoteImageLoadState = .loading

    var body: some View {
        Group {
            #if canImport(UIKit)
            switch loadState {
            case .loading:
                GoodsImageSkeleton()
            case let .loaded(image):
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            case .failed:
                GoodsImageFallback(iconSize: placeholderIconSize)
            }
            #else
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                switch phase {
                case .empty:
                    GoodsImageSkeleton()
                case let .success(image):
                    GeometryReader { proxy in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    }
                case .failure:
                    GoodsImageFallback(iconSize: placeholderIconSize)
                @unknown default:
                    GoodsImageFallback(iconSize: placeholderIconSize)
                }
            }
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
        #if canImport(UIKit)
        .task(id: url) {
            await loadImage()
        }
        #endif
    }

    #if canImport(UIKit)
    @MainActor
    private func loadImage() async {
        loadState = .loading
        do {
            let data = try await GoodsRemoteImageDataLoader.loadData(from: url)
            guard let image = UIImage(data: data) else {
                throw GoodsRemoteImageLoadError.invalidImageData
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                loadState = .loaded(image)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                loadState = .failed
            }
        }
    }
    #endif
}

private enum GoodsRemoteImageLoadState {
    #if canImport(UIKit)
    case loaded(UIImage)
    #endif
    case loading
    case failed
}

private struct GoodsImageSkeleton: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white.opacity(0.24),
                    .white.opacity(0.1),
                    .white.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.24))
                    .frame(width: 48, height: 12)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(width: 72, height: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(14)
        }
        .opacity(isPulsing ? 0.72 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear {
            isPulsing = true
        }
    }
}

private struct GoodsImageFallback: View {
    var iconSize: CGFloat

    var body: some View {
        Image(systemName: "photo")
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .padding(12)
            .background(.white.opacity(0.12), in: Circle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
