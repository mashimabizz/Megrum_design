import MegrumDesign
import SwiftUI

/// Defers building heavy content by one frame so the triggering interaction
/// (tab switch, slide-in presentation) commits immediately instead of
/// freezing while the destination view tree is constructed. Shows a light
/// canvas placeholder for the first frames, then swaps in the real content.
/// Once built, the content stays alive for the wrapper's lifetime.
enum MegrumDeferredContentDelay {
    /// タブ切替など：1フレームだけ譲って即構築。
    static let firstFrame: UInt64 = 30_000_000
    /// 右スライド遷移など：アニメーション（~0.32s）が終わってから構築。
    /// 遷移中に重いビュー構築が走るとスライドがカクつくため。
    static let slidePresentation: UInt64 = 340_000_000
}

struct MegrumDeferredContent<Content: View>: View {
    @State private var isReady = false

    private let delayNanoseconds: UInt64
    private let content: () -> Content

    init(
        delayNanoseconds: UInt64 = MegrumDeferredContentDelay.firstFrame,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.delayNanoseconds = delayNanoseconds
        self.content = content
    }

    var body: some View {
        ZStack {
            if isReady {
                content()
            } else {
                MegrumDeferredContentSkeleton()
            }
        }
        .task {
            guard !isReady else {
                return
            }
            // Give the transition time to commit before building content.
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            isReady = true
        }
    }
}

/// Generic screen skeleton (title bar + content rows) shown for the frames
/// while the deferred screen is being built — reads as the page loading in,
/// not as a spinner interstitial.
private struct MegrumDeferredContentSkeleton: View {
    var body: some View {
        MegrumTheme.canvas
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 18) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MegrumTheme.ink.opacity(0.08))
                        .frame(width: 148, height: 30)
                        .padding(.top, 18)

                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(MegrumTheme.ink.opacity(0.05))
                            .frame(height: 72)
                    }
                }
                .padding(.horizontal, 20)
            }
            .allowsHitTesting(false)
    }
}
