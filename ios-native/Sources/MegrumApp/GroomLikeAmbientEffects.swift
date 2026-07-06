import MegrumCore
import MegrumDesign
import SwiftUI

/// いいね数に応じて湧き出すハートの量を決める（項目10）。
/// 1〜10＝少し / 10〜50＝そこそこ / 50以上＝たくさん。
enum GroomLikeHeartRainPolicy {
    static func heartCount(forLikeCount likeCount: Int) -> Int {
        switch likeCount {
        case ..<1:
            return 0
        case ..<10:
            return 8
        case ..<50:
            return 16
        default:
            return 28
        }
    }
}

/// グルーム背景から小さなハートがばーっと湧き上がるレイヤー。
/// グルームを開いた時（切り替えた時）に、いいねが付いていれば1回再生する。
struct GroomLikeHeartRainLayer: View {
    var groomID: UUID
    var likeCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var seeds: [Seed] = []

    struct Seed: Identifiable {
        let id = UUID()
        let xRatio: CGFloat
        let size: CGFloat
        let delay: Double
        let duration: Double
        let drift: CGFloat
        let riseRatio: CGFloat
        let isPink: Bool
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(seeds) { seed in
                    GroomRisingHeart(seed: seed, containerSize: proxy.size)
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: groomID) {
            seeds = []
            guard !reduceMotion else {
                return
            }
            let count = GroomLikeHeartRainPolicy.heartCount(forLikeCount: likeCount)
            guard count > 0 else {
                return
            }
            // 開いた直後の描画が落ち着いてから再生する。
            try? await Task.sleep(nanoseconds: 350_000_000)
            seeds = (0..<count).map { _ in
                Seed(
                    xRatio: CGFloat.random(in: 0.08...0.92),
                    size: CGFloat.random(in: 9...17),
                    delay: Double.random(in: 0...0.9),
                    duration: Double.random(in: 1.2...2.2),
                    drift: CGFloat.random(in: -34...34),
                    riseRatio: CGFloat.random(in: 0.45...0.72),
                    isPink: Bool.random()
                )
            }
        }
    }
}

private struct GroomRisingHeart: View {
    let seed: GroomLikeHeartRainLayer.Seed
    let containerSize: CGSize

    @State private var isRisen = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: seed.size, weight: .heavy))
            .foregroundStyle(seed.isPink ? MegrumTheme.pink : .white.opacity(0.85))
            .position(
                x: containerSize.width * seed.xRatio + (isRisen ? seed.drift : 0),
                y: isRisen
                    ? containerSize.height * (1 - seed.riseRatio)
                    : containerSize.height + seed.size
            )
            .opacity(isRisen ? 0 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: seed.duration).delay(seed.delay)) {
                    isRisen = true
                }
            }
    }
}

/// 自分のグルームにいいねが付いている時、いいねしたユーザーのアイコン＋ハートが
/// 下からふわふわ浮かんでくるレイヤー（項目12。コメント本文は出さない）。
struct GroomLikeFloatingLikersLayer: View {
    var groomID: UUID
    var likers: [GroomFloatingLiker]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleLikers: [GroomFloatingLiker] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(visibleLikers.enumerated()), id: \.element.id) { index, liker in
                    GroomFloatingLikerBubble(
                        liker: liker,
                        index: index,
                        containerSize: proxy.size
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: groomID) {
            visibleLikers = []
            guard !reduceMotion, !likers.isEmpty else {
                return
            }
            try? await Task.sleep(nanoseconds: 550_000_000)
            visibleLikers = Array(likers.prefix(5))
        }
    }
}

struct GroomFloatingLiker: Identifiable, Equatable {
    var id: UUID
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
}

private struct GroomFloatingLikerBubble: View {
    let liker: GroomFloatingLiker
    let index: Int
    let containerSize: CGSize

    @State private var isRisen = false
    @State private var wobble = false

    private var xPosition: CGFloat {
        // 左下寄りから順にずらして出す。
        let ratios: [CGFloat] = [0.16, 0.26, 0.12, 0.3, 0.2]
        return containerSize.width * ratios[index % ratios.count]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BoardThreadDetailAvatar(
                avatarID: liker.avatarID,
                imageURL: liker.avatarURL,
                initial: liker.initial,
                size: 34
            )
            .overlay {
                Circle().stroke(.white.opacity(0.8), lineWidth: 1.5)
            }

            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .padding(3)
                .background(MegrumTheme.pink, in: Circle())
                .offset(x: 5, y: 5)
        }
        .offset(x: wobble ? 7 : -7)
        .position(
            x: xPosition,
            y: isRisen ? containerSize.height * 0.5 : containerSize.height - 60
        )
        .opacity(isRisen ? 0 : 1)
        .onAppear {
            let delay = Double(index) * 0.55
            withAnimation(.easeOut(duration: 2.4).delay(delay)) {
                isRisen = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(delay)) {
                wobble = true
            }
        }
    }
}
