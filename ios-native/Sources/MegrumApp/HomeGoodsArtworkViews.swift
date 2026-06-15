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
                    switch goods.shape {
                    case .portrait:
                        portrait(in: size)
                    case .badge:
                        badge(in: size)
                    case .stand:
                        stand(in: size)
                    case .keychain:
                        keychain(in: size)
                    case .plush:
                        plush(in: size)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func portrait(in size: CGSize) -> some View {
        let headDiameter = HomeGoodsArtworkLayout.portraitHeadDiameter(in: size)
        let bodySize = HomeGoodsArtworkLayout.portraitBodySize(in: size)

        return VStack(spacing: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.06)) {
            Circle()
                .fill(.white.opacity(0.30))
                .frame(width: headDiameter, height: headDiameter)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(9, headDiameter * 0.52), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

            Capsule()
                .fill(.white.opacity(0.28))
                .frame(width: bodySize.width, height: bodySize.height)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.34))
                        .frame(width: bodySize.width * 0.60, height: bodySize.height * 0.46)
                        .padding(.top, bodySize.height * 0.10)
                }
        }
        .shadow(color: .black.opacity(0.12), radius: max(4, HomeGoodsArtworkLayout.unit(in: size) * 0.08), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func badge(in size: CGSize) -> some View {
        let diameter = HomeGoodsArtworkLayout.badgeDiameter(in: size)

        return Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.90), MegrumTheme.sky.opacity(0.44), MegrumTheme.lavender.opacity(0.30)],
                    center: .center,
                    startRadius: 4,
                    endRadius: diameter * 0.75
                )
            )
            .frame(width: diameter, height: diameter)
            .overlay {
                Text(goods.symbol)
                    .font(.system(size: max(9, diameter * 0.36), weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .overlay(Circle().stroke(.white.opacity(0.88), lineWidth: max(1, diameter * 0.03)))
            .shadow(color: .black.opacity(0.12), radius: max(4, diameter * 0.09), y: max(2, diameter * 0.05))
    }

    private func stand(in size: CGSize) -> some View {
        let figureSize = HomeGoodsArtworkLayout.standFigureSize(in: size)
        let baseSize = HomeGoodsArtworkLayout.standBaseSize(in: size)

        return VStack(spacing: 0) {
            Capsule()
                .fill(MegrumTheme.lavender.opacity(0.30))
                .frame(width: figureSize.width, height: figureSize.height)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(8, figureSize.width * 0.62), weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }

            Ellipse()
                .fill(.white.opacity(0.78))
                .frame(width: baseSize.width, height: baseSize.height)
                .overlay(Ellipse().stroke(MegrumTheme.lavender.opacity(0.28), lineWidth: 1))
        }
        .shadow(color: .black.opacity(0.10), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func keychain(in size: CGSize) -> some View {
        let ringDiameter = HomeGoodsArtworkLayout.keychainRingDiameter(in: size)
        let heartSize = HomeGoodsArtworkLayout.keychainHeartSize(in: size)

        return VStack(spacing: -max(1, HomeGoodsArtworkLayout.unit(in: size) * 0.04)) {
            Circle()
                .stroke(MegrumTheme.lavender.opacity(0.54), lineWidth: max(1.2, ringDiameter * 0.18))
                .frame(width: ringDiameter, height: ringDiameter)

            Image(systemName: "heart.fill")
                .font(.system(size: heartSize, weight: .bold))
                .foregroundStyle(MegrumTheme.pink.opacity(0.70))
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(8, heartSize * 0.28), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
        }
        .shadow(color: .black.opacity(0.12), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
    }

    private func plush(in size: CGSize) -> some View {
        let headDiameter = HomeGoodsArtworkLayout.plushHeadDiameter(in: size)
        let bodySize = HomeGoodsArtworkLayout.plushBodySize(in: size)

        return VStack(spacing: -max(1, HomeGoodsArtworkLayout.unit(in: size) * 0.02)) {
            Circle()
                .fill(MegrumTheme.lavender.opacity(0.48))
                .frame(width: headDiameter, height: headDiameter)
                .overlay {
                    Text(goods.symbol)
                        .font(.system(size: max(9, headDiameter * 0.42), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            Capsule()
                .fill(MegrumTheme.lavender.opacity(0.35))
                .frame(width: bodySize.width, height: bodySize.height)
        }
        .shadow(color: .black.opacity(0.10), radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07), y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04))
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
