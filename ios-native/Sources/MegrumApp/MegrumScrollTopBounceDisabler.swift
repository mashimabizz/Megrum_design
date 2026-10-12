import SwiftUI

#if os(iOS)
import UIKit

/// シート内スクロールのバウンス制御（iter1226.424 → iter1226.460 改訂）。
///
/// 旧実装は `bounces = false` の常時固定だった。しかし iOS のシート（UISheetPresentationController）
/// は「最上部でのバウンス機構」を使って下ドラッグをシートの dismiss ジェスチャへ引き継ぐため、
/// バウンスを常時切るとシートを引き下げて閉じる操作が効かなくなっていた（オーナー報告：
/// スクロール後に下スワイプしてもシートが閉じない）。
///
/// 改訂：contentOffset を監視して**最上部にいる時だけ bounces を有効**にする。
/// - 最上部：bounces=true → 下ドラッグがそのままシートの閉じ操作になる（iOS標準挙動）
/// - スクロール中：bounces=false → 下端のオーバースクロール（上限以上のスクロール）は起きない
private struct MegrumEnclosingScrollBounceDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> DisablerView {
        DisablerView()
    }

    func updateUIView(_ uiView: DisablerView, context: Context) {
        uiView.scheduleConfiguration()
    }

    final class DisablerView: UIView {
        private weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleConfiguration()
        }

        func scheduleConfiguration() {
            DispatchQueue.main.async { [weak self] in
                self?.configureEnclosingScrollView()
            }
        }

        private func configureEnclosingScrollView() {
            guard offsetObservation == nil else {
                return
            }
            var view: UIView? = superview
            while let current = view {
                if let enclosing = current as? UIScrollView {
                    scrollView = enclosing
                    enclosing.alwaysBounceVertical = false
                    applyBouncePolicy(to: enclosing)
                    offsetObservation = enclosing.observe(\.contentOffset, options: [.new]) { [weak self] observed, _ in
                        self?.applyBouncePolicy(to: observed)
                    }
                    return
                }
                view = current.superview
            }
        }

        private func applyBouncePolicy(to scrollView: UIScrollView) {
            let topOffset = -scrollView.adjustedContentInset.top
            let isAtTop = scrollView.contentOffset.y <= topOffset + 1
            if scrollView.bounces != isAtTop {
                scrollView.bounces = isAtTop
            }
        }
    }
}

extension View {
    /// スクロールコンテンツの内側に付ける：直近の外側スクロールを
    /// 「最上部でだけバウンス可（＝シートの引き下げ閉じが効く）／
    /// スクロール中は下端オーバースクロール不可」にする。
    func megrumDisablesEnclosingScrollBounce() -> some View {
        background {
            MegrumEnclosingScrollBounceDisabler()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}
#else
extension View {
    func megrumDisablesEnclosingScrollBounce() -> some View {
        self
    }
}
#endif
