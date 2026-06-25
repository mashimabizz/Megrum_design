import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum HomeGoodsArtworkLayout {
    static func unit(in size: CGSize) -> CGFloat {
        max(1, min(size.width, size.height))
    }

    static func portraitHeadDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.43, size.width * 0.62, size.height * 0.38)
    }

    static func portraitBodySize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.40, size.width * 0.56),
            height: min(base * 0.58, size.height * 0.44)
        )
    }

    static func badgeDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.76, size.width * 0.82, size.height * 0.82)
    }

    static func standFigureSize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.34, size.width * 0.42),
            height: min(base * 0.74, size.height * 0.68)
        )
    }

    static func standBaseSize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.58, size.width * 0.76),
            height: min(base * 0.15, size.height * 0.14)
        )
    }

    static func keychainRingDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.20, size.width * 0.30, size.height * 0.18)
    }

    static func keychainHeartSize(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.62, size.width * 0.74, size.height * 0.66)
    }

    static func plushHeadDiameter(in size: CGSize) -> CGFloat {
        let base = unit(in: size)
        return min(base * 0.58, size.width * 0.68, size.height * 0.54)
    }

    static func plushBodySize(in size: CGSize) -> CGSize {
        let base = unit(in: size)
        return CGSize(
            width: min(base * 0.54, size.width * 0.66),
            height: min(base * 0.36, size.height * 0.32)
        )
    }
}

struct HomeGoodsArtwork: View {
    var goods: HomeMockGoods

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: goods.palette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let imageURL = goods.imageURL {
                    HomeActualGoodsImage(url: imageURL, fallbackPalette: goods.palette)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    HomeGoodsPlaceholderArtwork(goods: goods, size: size)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }
}

private struct HomeActualGoodsImage: View {
    var url: URL
    var fallbackPalette: [Color]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: fallbackPalette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            loadedImage
        }
    }

    @ViewBuilder
    private var loadedImage: some View {
        if let platformImage = HomeLocalGoodsImageLoader.image(from: url) {
            platformImage
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

private enum HomeLocalGoodsImageLoader {
    static func image(from url: URL) -> Image? {
        guard url.isFileURL else {
            return nil
        }

        #if canImport(UIKit)
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}
