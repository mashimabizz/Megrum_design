import SwiftUI

#if os(iOS)
import UIKit

/// シート内スクロールの端バウンスを止める（iter1226.424）。
/// 候補シートでは最上部からさらに下へ引いた時に中身がバウンスすると、
/// シートを閉じるためのドラッグが奪われて閉じられないことがある。
/// バウンスを切ると、最上部からの下ドラッグがそのままシートの
/// dismiss ジェスチャへ渡る。
private struct MegrumEnclosingScrollBounceDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> DisablerView {
        DisablerView()
    }

    func updateUIView(_ uiView: DisablerView, context: Context) {
        uiView.scheduleDisabling()
    }

    final class DisablerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleDisabling()
        }

        func scheduleDisabling() {
            DispatchQueue.main.async { [weak self] in
                self?.disableEnclosingScrollBounce()
            }
        }

        private func disableEnclosingScrollBounce() {
            var view: UIView? = superview
            while let current = view {
                if let scrollView = current as? UIScrollView {
                    scrollView.bounces = false
                    scrollView.alwaysBounceVertical = false
                    return
                }
                view = current.superview
            }
        }
    }
}

extension View {
    /// スクロールコンテンツの内側に付ける：直近の外側スクロールのバウンスを無効化する。
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
