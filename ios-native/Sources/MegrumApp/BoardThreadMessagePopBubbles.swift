import MegrumDesign
import SwiftUI

/// 地図のチャットルームピン上に、最新メッセージをポップに出したり消したりする吹き出し。
/// 「どういう話をしてるのかな？」と気になってもらうための演出（最大3件を循環）。
/// アイコンの真上だけでなく左横・右横からも「ぽんっ」と現れ、
/// 消える時は上へふわっと蒸発するようにフェードアウトする。
struct BoardThreadMessagePopBubbles: View {
    var previews: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleIndex: Int?
    @State private var cycleTask: Task<Void, Never>?

    private static let previewLimit = 20

    /// 吹き出しの出現位置（アイコンから見てどちら側に出るか）。
    private enum BubblePlacement: CaseIterable {
        case top
        case left
        case right

        /// アイコン上端アンカー（overlay .top / offset -30）からの相対位置。
        var offset: CGSize {
            switch self {
            case .top:
                CGSize(width: 0, height: 0)
            case .left:
                CGSize(width: -58, height: 16)
            case .right:
                CGSize(width: 58, height: 16)
            }
        }

        /// 「ぽんっ」の起点。アイコン側から膨らむように見せる。
        var popAnchor: UnitPoint {
            switch self {
            case .top:
                .bottom
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
                Text(truncated(previews[visibleIndex]))
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.96), in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(MegrumTheme.sky.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
                    .fixedSize()
                    .offset(placement.offset)
                    .transition(.asymmetric(
                        // ぽんっ：アイコン側を起点に弾んで膨らむ
                        insertion: .scale(scale: 0.3, anchor: placement.popAnchor)
                            .combined(with: .opacity),
                        // 蒸発：上へふわっと昇りながら薄れて消える
                        removal: .offset(y: -22)
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

    /// 出現位置をピンごと・メッセージごとに変える（決定的：resumeでも揺れない）。
    private func placement(for index: Int) -> BubblePlacement {
        let seed = abs((previews.first?.hashValue ?? 0) &+ index)
        let cases = BubblePlacement.allCases
        return cases[seed % cases.count]
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
            var index = 0
            while !Task.isCancelled {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.58)) {
                    visibleIndex = index
                }
                try? await Task.sleep(nanoseconds: 2_300_000_000)
                if Task.isCancelled {
                    return
                }
                withAnimation(.easeOut(duration: 0.5)) {
                    visibleIndex = nil
                }
                try? await Task.sleep(nanoseconds: 900_000_000)
                index = (index + 1) % max(previews.count, 1)
            }
        }
    }
}
