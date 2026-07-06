import MegrumDesign
import SwiftUI

/// 地図のチャットルームピン横に、最新メッセージをポップに出したり消したりする吹き出し。
/// 「どういう話をしてるのかな？」と気になってもらうための演出（最大3件を循環）。
/// - 左横 / 右横からアイコンへ矢印（しっぽ）が向いた吹き出しで「ぽんっ」と現れる（真上には出さない）
/// - 出た直後からゆっくり上へ昇り続け、最後は蒸発するようにフェードアウトする
/// - 出るタイミングはピンごとにランダム（複数ピンで同時に出て被らないように）
struct BoardThreadMessagePopBubbles: View {
    var previews: [String]
    var seed: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleIndex: Int?
    @State private var driftOffset: CGFloat = 0
    @State private var cycleTask: Task<Void, Never>?

    private static let previewLimit = 20

    /// 吹き出しの出現位置（アイコンから見てどちら側に出るか）。真上は使わない。
    private enum BubblePlacement: CaseIterable {
        case left
        case right

        /// アイコン上端アンカー（overlay .top / offset -30）からの相対位置。
        /// 右横はアイコン右上のバッジと重ならないよう、外側かつ低めに出す。
        var offset: CGSize {
            switch self {
            case .left:
                CGSize(width: -62, height: 22)
            case .right:
                CGSize(width: 70, height: 38)
            }
        }

        /// 「ぽんっ」の起点。アイコン側から膨らむように見せる。
        var popAnchor: UnitPoint {
            switch self {
            case .left:
                .bottomTrailing
            case .right:
                .bottomLeading
            }
        }
    }

    var body: some View {
        ZStack {
            if let visibleIndex, previews.indices.contains(visibleIndex) {
                let placement = placement(for: visibleIndex)
                bubble(text: truncated(previews[visibleIndex]), placement: placement)
                    .fixedSize()
                    .offset(placement.offset)
                    .offset(y: driftOffset)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3, anchor: placement.popAnchor)
                            .combined(with: .opacity),
                        removal: .offset(y: -18)
                            .combined(with: .scale(scale: 0.86, anchor: .center))
                            .combined(with: .opacity)
                    ))
                    .id(visibleIndex)
            }
        }
        .frame(maxWidth: 150)
        .allowsHitTesting(false)
        .onAppear {
            startCycling()
        }
        .onDisappear {
            cycleTask?.cancel()
            cycleTask = nil
        }
    }

    /// 矢印（しっぽ）付きの吹き出し。しっぽはアイコン側の下角から斜め下へ向く。
    private func bubble(text: String, placement: BubblePlacement) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.white.opacity(0.96), in: Capsule())
            .overlay {
                Capsule().strokeBorder(MegrumTheme.sky.opacity(0.5), lineWidth: 1)
            }
            .overlay(alignment: placement == .left ? .bottomTrailing : .bottomLeading) {
                BubbleTail(pointsTowardTrailing: placement == .left)
                    .fill(.white.opacity(0.96))
                    .overlay {
                        BubbleTail(pointsTowardTrailing: placement == .left)
                            .stroke(MegrumTheme.sky.opacity(0.5), lineWidth: 1)
                    }
                    .frame(width: 11, height: 10)
                    .offset(
                        x: placement == .left ? 6 : -6,
                        y: 7
                    )
            }
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
    }

    /// 出現位置をピンごと・メッセージごとに変える（決定的：再描画でも揺れない）。
    private func placement(for index: Int) -> BubblePlacement {
        let mixed = abs((previews.first?.hashValue ?? 0) &+ seed &+ index)
        let cases = BubblePlacement.allCases
        return cases[mixed % cases.count]
    }

    private func truncated(_ text: String) -> String {
        let flattened = text.replacingOccurrences(of: "\n", with: " ")
        guard flattened.count > Self.previewLimit else {
            return flattened
        }
        return String(flattened.prefix(Self.previewLimit)) + "…"
    }

    private func startCycling() {
        guard !previews.isEmpty, !reduceMotion else {
            return
        }
        cycleTask?.cancel()
        cycleTask = Task { @MainActor in
            // ピンごとに異なる擬似乱数列（xorshift）。開始タイミングと間隔をずらして
            // 複数ピンの吹き出しが同時に出ないようにする。
            var randomState = UInt64(bitPattern: Int64(seed == 0 ? 0x9E3779B9 : seed)) | 1
            func nextRandom(_ range: ClosedRange<UInt64>) -> UInt64 {
                randomState ^= randomState << 13
                randomState ^= randomState >> 7
                randomState ^= randomState << 17
                return range.lowerBound + randomState % (range.upperBound - range.lowerBound + 1)
            }

            // 初回はピンごとにランダムな待ち（0.2〜2.6秒）を入れる。
            try? await Task.sleep(nanoseconds: nextRandom(200...2_600) * 1_000_000)

            var index = 0
            while !Task.isCancelled {
                driftOffset = 0
                withAnimation(.spring(response: 0.34, dampingFraction: 0.58)) {
                    visibleIndex = index
                }
                // 出た直後から表示中ずっと、ゆっくり上へ昇り続ける。
                withAnimation(.easeOut(duration: 2.6)) {
                    driftOffset = -16
                }
                try? await Task.sleep(nanoseconds: nextRandom(1_900...2_700) * 1_000_000)
                if Task.isCancelled {
                    return
                }
                withAnimation(.easeOut(duration: 0.5)) {
                    visibleIndex = nil
                }
                try? await Task.sleep(nanoseconds: nextRandom(700...1_800) * 1_000_000)
                index = (index + 1) % max(previews.count, 1)
            }
        }
    }
}

/// 吹き出しのしっぽ（アイコン側へ向く小さな三角形）。
private struct BubbleTail: Shape {
    /// true なら右下（trailing）方向へ、false なら左下（leading）方向へ向く。
    var pointsTowardTrailing: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsTowardTrailing {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.45))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45))
        }
        path.closeSubpath()
        return path
    }
}
