import MegrumDesign
import SwiftUI

/// 地図のチャットルームピン上に、最新メッセージをポップに出したり消したりする吹き出し。
/// 「どういう話をしてるのかな？」と気になってもらうための演出（最大3件を循環）。
struct BoardThreadMessagePopBubbles: View {
    var previews: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleIndex: Int?
    @State private var cycleTask: Task<Void, Never>?

    private static let previewLimit = 20

    var body: some View {
        ZStack {
            if let visibleIndex, previews.indices.contains(visibleIndex) {
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
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.4, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.7, anchor: .bottom).combined(with: .opacity)
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
                withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                    visibleIndex = index
                }
                try? await Task.sleep(nanoseconds: 2_300_000_000)
                if Task.isCancelled {
                    return
                }
                withAnimation(.easeIn(duration: 0.24)) {
                    visibleIndex = nil
                }
                try? await Task.sleep(nanoseconds: 900_000_000)
                index = (index + 1) % max(previews.count, 1)
            }
        }
    }
}
