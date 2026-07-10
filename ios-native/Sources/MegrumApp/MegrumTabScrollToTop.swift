import SwiftUI

#if os(iOS)
import UIKit

/// タブバーの「表示中タブ再タップ」で、そのタブの縦スクロールを最上部へ戻す（iter1226.429）。
/// signal が変わるたびに、近くの祖先から幅優先でタブ直下の縦スクロールビューを探して
/// アニメーション付きで先頭へ戻す。各画面へ個別のアンカー実装を足さずに済む。
private struct MegrumTabScrollToTopEffect: UIViewRepresentable {
    let signal: Int

    func makeUIView(context: Context) -> EffectView {
        EffectView()
    }

    func updateUIView(_ uiView: EffectView, context: Context) {
        uiView.handleSignal(signal)
    }

    final class EffectView: UIView {
        private var lastSignal: Int?

        func handleSignal(_ signal: Int) {
            guard let lastSignal else {
                self.lastSignal = signal
                return
            }
            guard signal != lastSignal else {
                return
            }
            self.lastSignal = signal
            DispatchQueue.main.async { [weak self] in
                self?.scrollEnclosingContentToTop()
            }
        }

        private func scrollEnclosingContentToTop() {
            // タブコンテンツを包む十分に広い祖先まで上がってから、幅優先で
            // 最初の「縦にスクロールする」UIScrollView を探す（外側が先に見つかる）。
            var host: UIView? = superview
            while let current = host, current.bounds.width < UIScreen.main.bounds.width - 1 {
                host = current.superview
            }
            guard let root = host else {
                return
            }
            var queue: [UIView] = [root]
            var index = 0
            while index < queue.count {
                let view = queue[index]
                index += 1
                if let scrollView = view as? UIScrollView, scrollsVertically(scrollView) {
                    let top = CGPoint(
                        x: scrollView.contentOffset.x,
                        y: -scrollView.adjustedContentInset.top
                    )
                    guard scrollView.contentOffset.y > top.y + 1 else {
                        return
                    }
                    scrollView.setContentOffset(top, animated: true)
                    return
                }
                queue.append(contentsOf: view.subviews)
            }
        }

        private func scrollsVertically(_ scrollView: UIScrollView) -> Bool {
            scrollView.contentSize.height > scrollView.bounds.height - scrollView.adjustedContentInset.top
                || scrollView.alwaysBounceVertical
        }
    }
}

extension View {
    /// タブのコンテンツに付ける：signal が増えるたびに縦スクロールを先頭へ戻す。
    func megrumScrollsToTopOnTabReselection(signal: Int) -> some View {
        background {
            MegrumTabScrollToTopEffect(signal: signal)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}
#else
extension View {
    func megrumScrollsToTopOnTabReselection(signal: Int) -> some View {
        self
    }
}
#endif
