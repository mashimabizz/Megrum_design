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

        /// しっぽ先端を固定する「端アンカー」の位置。
        /// コンテナ（overlay .top / offset -30 → アイコン上端中央の少し上）基準。
        /// 吹き出しはこの点からアイコンの外側へ向かって伸びるため、
        /// 文章が長くなってもしっぽがアイコンに被ったりズレたりしない。
        /// 右側はアイコン右上のバッジ（クラスタ数）を避けて外側・低めに置く。
        var anchorOffset: CGSize {
            switch self {
            case .left:
                CGSize(width: -36, height: 50)
            case .right:
                CGSize(width: 42, height: 58)
            }
        }

        /// アンカーから吹き出しが伸びる向き（＝しっぽ側の角を固定する）。
        var growthAlignment: Alignment {
            switch self {
            case .left:
                .bottomTrailing
            case .right:
                .bottomLeading
            }
        }

        /// 「ぽんっ」の起点。アイコン側（しっぽ側）から膨らむように見せる。
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
                Color.clear
                    .frame(width: 1, height: 1)
                    .overlay(alignment: placement.growthAlignment) {
                        bubble(text: truncated(previews[visibleIndex]), placement: placement)
                            .fixedSize()
                    }
                    .offset(placement.anchorOffset)
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
        // しっぽ込みの輪郭を1本のパスで描く（サブパスの重なりを使わない）。
        // 別サブパスで三角を重ねると巻き方向次第で nonzero 塗りが相殺されて
        // 本体としっぽの間に切れ目が出るため（左側出現時の形崩れの原因）、
        // 底辺の途中にしっぽを織り込んだ完全ミラーの単一輪郭にする。
        let tailHeight = Self.tailHeight
        let tailWidth = Self.tailWidth
        let radius = cornerRadius
        let body = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - tailHeight
        )

        var path = Path()
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        // 上辺 → 右上角
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        // 右辺 → 右下角
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addArc(
            center: CGPoint(x: body.maxX - radius, y: body.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        // 底辺（右→左）。trailing 側のしっぽはここに織り込む。
        if tailOnTrailing {
            let baseEnd = body.maxX - radius - 1
            let baseStart = baseEnd - tailWidth
            let tip = CGPoint(x: body.maxX + 2, y: rect.maxY)
            path.addLine(to: CGPoint(x: baseEnd, y: body.maxY))
            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: baseEnd + 1, y: body.maxY + tailHeight * 0.45)
            )
            path.addQuadCurve(
                to: CGPoint(x: baseStart, y: body.maxY),
                control: CGPoint(x: baseStart + tailWidth * 0.3, y: body.maxY + tailHeight * 0.5)
            )
        }
        if !tailOnTrailing {
            let baseStart = body.minX + radius + 1
            let baseEnd = baseStart + tailWidth
            let tip = CGPoint(x: body.minX - 2, y: rect.maxY)
            path.addLine(to: CGPoint(x: baseEnd, y: body.maxY))
            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: baseEnd - tailWidth * 0.3, y: body.maxY + tailHeight * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: baseStart, y: body.maxY),
                control: CGPoint(x: baseStart - 1, y: body.maxY + tailHeight * 0.45)
            )
        }
        // 左下角
        path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        // 左辺 → 左上角
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addArc(
            center: CGPoint(x: body.minX + radius, y: body.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
