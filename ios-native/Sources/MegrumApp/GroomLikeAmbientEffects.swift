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
                    riseRatio: CGFloat.random(in: 0.45...0.72)
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
            // いいねアイコン（赤）と同じ色に揃える
            .foregroundStyle(Color.red.opacity(0.9))
            .position(
                x: containerSize.width * seed.xRatio + (isRisen ? seed.drift : 0),
                y: isRisen
                    ? containerSize.height * (1 - seed.riseRatio)
                    : containerSize.height + seed.size
            )
            .opacity(isRisen ? 0 : 0.95)
            .onAppear {
                // 出はじめと消えぎわがゆっくりになるイージング
                withAnimation(.easeInOut(duration: seed.duration).delay(seed.delay)) {
                    isRisen = true
                }
            }
    }
}

/// 自分のグルームにいいねが付いている時、いいねしたユーザーを1人ずつ見せるレイヤー。
/// 左下にユーザーアイコン（右下にハート付き）がゆっくり現れて約1秒とどまり、
/// ゆっくり上へ昇りながらフェードアウトしていく。
struct GroomLikeFloatingLikersLayer: View {
    var groomID: UUID
    var likers: [GroomFloatingLiker]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentLiker: GroomFloatingLiker?
    @State private var phase: LikerPhase = .hidden

    private enum LikerPhase {
        case hidden
        case visible
        case leaving
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let currentLiker {
                GroomFloatingLikerBadge(liker: currentLiker)
                    .opacity(phase == .visible ? 1 : 0)
                    .offset(y: phase == .leaving ? -110 : (phase == .hidden ? 10 : 0))
                    .padding(.leading, 20)
                    .padding(.bottom, 130)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .allowsHitTesting(false)
        .task(id: groomID) {
            currentLiker = nil
            phase = .hidden
            guard !reduceMotion, !likers.isEmpty else {
                return
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            for liker in likers.prefix(6) {
                if Task.isCancelled { return }
                currentLiker = liker
                phase = .hidden
                // ゆっくり現れる
                withAnimation(.easeOut(duration: 0.7)) {
                    phase = .visible
                }
                try? await Task.sleep(nanoseconds: 1_700_000_000)
                if Task.isCancelled { return }
                // ゆっくり上へ昇りながら消える
                withAnimation(.easeIn(duration: 1.1)) {
                    phase = .leaving
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                currentLiker = nil
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
        }
    }
}

struct GroomFloatingLiker: Identifiable, Equatable {
    var id: UUID
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
}

/// いいねしたユーザーのアイコン＋右下ハート（グッズ交換用プロフィールのアイコンを使用）。
private struct GroomFloatingLikerBadge: View {
    let liker: GroomFloatingLiker

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BoardThreadDetailAvatar(
                avatarID: nil,
                imageURL: liker.avatarURL,
                initial: liker.initial,
                size: 46
            )
            .overlay {
                Circle().stroke(.white.opacity(0.85), lineWidth: 1.5)
            }

            Image(systemName: "heart.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .padding(3.5)
                .background(Color.red, in: Circle())
                .offset(x: 6, y: 6)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
    }
}

/// ダブルタップいいねの大きなハート。
struct GroomDoubleTapHeart: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
}

/// タップ位置に「ドクン」と現れて、そのまま上へふわりふわり揺れながら
/// フェードアウトしていく大きなハート。
struct GroomDoubleTapHeartView: View {
    var position: CGPoint

    @State private var thumpScale: CGFloat = 0.25
    @State private var rise: CGFloat = 0
    @State private var sway = false
    @State private var fade: Double = 1

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 88, weight: .heavy))
            .foregroundStyle(Color.red.opacity(0.92))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            .scaleEffect(thumpScale)
            .offset(x: sway ? 14 : -14)
            .position(x: position.x, y: position.y + rise)
            .opacity(fade)
            .allowsHitTesting(false)
            .onAppear {
                // ドクン：一気に膨らんで少し戻る（心拍のような弾み）
                withAnimation(.spring(response: 0.24, dampingFraction: 0.42)) {
                    thumpScale = 1.0
                }
                // ふわりふわり：左右に揺れながらゆっくり上昇してフェードアウト
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    sway = true
                }
                withAnimation(.easeInOut(duration: 1.4).delay(0.35)) {
                    rise = -190
                }
                withAnimation(.easeIn(duration: 1.0).delay(0.7)) {
                    fade = 0
                }
            }
    }
}
