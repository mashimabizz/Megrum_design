import MegrumDesign
import SwiftUI

struct HomeGoodsPlaceholderArtwork: View {
    var goods: HomeMockGoods
    var size: CGSize

    var body: some View {
        switch goods.shape {
        case .portrait:
            portrait
        case .badge:
            badge
        case .stand:
            stand
        case .keychain:
            keychain
        case .plush:
            plush
        }
    }

    private var portrait: some View {
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
        .shadow(
            color: .black.opacity(0.12),
            radius: max(4, HomeGoodsArtworkLayout.unit(in: size) * 0.08),
            y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04)
        )
    }

    private var badge: some View {
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

    private var stand: some View {
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
        .shadow(
            color: .black.opacity(0.10),
            radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07),
            y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04)
        )
    }

    private var keychain: some View {
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
        .shadow(
            color: .black.opacity(0.12),
            radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07),
            y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04)
        )
    }

    private var plush: some View {
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
        .shadow(
            color: .black.opacity(0.10),
            radius: max(3, HomeGoodsArtworkLayout.unit(in: size) * 0.07),
            y: max(2, HomeGoodsArtworkLayout.unit(in: size) * 0.04)
        )
    }
}
