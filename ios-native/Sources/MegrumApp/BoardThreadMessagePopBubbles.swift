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

    private static let previewLimit = 48

    /// 吹き出しの出現位置（アイコンから見てどちら側に出るか）。真上は使わない。
    private enum BubblePlacement: CaseIterable {
        case left
        case right

        /// アイコン上端アンカー（overlay .top / offset -30）からの相対位置。
        /// 右横はアイコン右上のバッジと重ならないよう、外側かつ低めに出す。
        var offset: CGSize {
            switch self {
            case .left:
                CGSize(width: -66, height: 18)
            case .right:
                CGSize(width: 74, height: 38)
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
        .frame(maxWidth: 170)
        .allowsHitTesting(false)
        .onAppear {
            startCycling()
        }
        .onDisappear {
            cycleTask?.cancel()
            cycleTask = nil
        }
    }

    /// しっぽまで一体の吹き出し。しっぽはアイコン側の下角からなめらかにアイコンへ向く。
    /// 長文は2行まで表示する。
    private func bubble(text: String, placement: BubblePlacement) -> some View {
        let shape = MapChatBubbleShape(tailOnTrailing: placement == .left)
        return Text(text)
            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: 148, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.top, 7)
            .padding(.bottom, 7 + MapChatBubbleShape.tailHeight)
            .background {
                shape
                    .fill(.white)
                    .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 7, y: 3)
                    .overlay {
                        // 本体としっぽの境目に線が出ないよう、輪郭線は引かず
                        // ごく薄いブランドトーンのグラデを重ねるだけにする。
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    MegrumTheme.sky.opacity(0.10),
                                    MegrumTheme.lavender.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
            }
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

/// 地図用チャット吹き出しの一体シェイプ：角丸の本体＋アイコン側の下角から
/// なめらかな曲線で伸びるしっぽを1つのパスで描く（継ぎ目が出ない）。
struct MapChatBubbleShape: Shape {
    static let tailHeight: CGFloat = 9
    static let tailWidth: CGFloat = 14

    var cornerRadius: CGFloat = 13
    /// true なら右下（trailing＝アイコンが右にある）へ、false なら左下へ向く。
    var tailOnTrailing: Bool

    func path(in rect: CGRect) -> Path {
        let tailHeight = Self.tailHeight
        let tailWidth = Self.tailWidth
        let body = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - tailHeight
        )
        var path = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)

        var tail = Path()
        if tailOnTrailing {
            let baseEnd = body.maxX - cornerRadius * 0.55
            let baseStart = baseEnd - tailWidth
            let tip = CGPoint(x: body.maxX + 2, y: rect.maxY)
            tail.move(to: CGPoint(x: baseStart, y: body.maxY - 1))
            tail.addQuadCurve(
                to: tip,
                control: CGPoint(x: baseStart + tailWidth * 0.55, y: body.maxY + tailHeight * 0.55)
            )
            tail.addQuadCurve(
                to: CGPoint(x: baseEnd, y: body.maxY - 1),
                control: CGPoint(x: baseEnd - tailWidth * 0.12, y: body.maxY + tailHeight * 0.32)
            )
        } else {
            let baseStart = body.minX + cornerRadius * 0.55
            let baseEnd = baseStart + tailWidth
            let tip = CGPoint(x: body.minX - 2, y: rect.maxY)
            tail.move(to: CGPoint(x: baseEnd, y: body.maxY - 1))
            tail.addQuadCurve(
                to: tip,
                control: CGPoint(x: baseEnd - tailWidth * 0.55, y: body.maxY + tailHeight * 0.55)
            )
            tail.addQuadCurve(
                to: CGPoint(x: baseStart, y: body.maxY - 1),
                control: CGPoint(x: baseStart + tailWidth * 0.12, y: body.maxY + tailHeight * 0.32)
            )
        }
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}
