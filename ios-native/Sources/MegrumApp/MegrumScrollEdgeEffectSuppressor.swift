import SwiftUI

#if os(iOS)
import UIKit

/// iOS 26+ attaches automatic scroll edge effects to scroll views that
/// underlap bars — and on iOS 27 they render as an opaque band over the tab
/// bar area. SwiftUI's `scrollEdgeEffectHidden` does not reach the
/// UIKit-hosted paging collection view on iOS 27, so this helper walks up the
/// UIKit hierarchy from inside the scroll content and hides the effects on
/// every enclosing scroll view directly.
private struct MegrumEnclosingScrollEdgeEffectSuppressor: UIViewRepresentable {
    func makeUIView(context: Context) -> SuppressorView {
        SuppressorView()
    }

    func updateUIView(_ uiView: SuppressorView, context: Context) {
        uiView.scheduleSuppression()
    }

    final class SuppressorView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleSuppression()
        }

        func scheduleSuppression() {
            DispatchQueue.main.async { [weak self] in
                self?.suppressEnclosingScrollEdgeEffects()
            }
        }

        private func suppressEnclosingScrollEdgeEffects() {
            guard #available(iOS 26.0, *) else {
                return
            }
            var view: UIView? = superview
            while let current = view {
                if let scrollView = current as? UIScrollView {
                    scrollView.topEdgeEffect.isHidden = true
                    scrollView.bottomEdgeEffect.isHidden = true
                }
                view = current.superview
            }
        }
    }
}

extension View {
    /// Attach inside scroll content: hides iOS 26+ scroll edge effects on all
    /// enclosing scroll views (the SwiftUI scroll itself and any UIKit paging
    /// container above it). The app draws its own top/bottom chrome instead.
    func megrumSuppressesEnclosingScrollEdgeEffects() -> some View {
        background {
            MegrumEnclosingScrollEdgeEffectSuppressor()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}
#else
extension View {
    func megrumSuppressesEnclosingScrollEdgeEffects() -> some View {
        self
    }
}
#endif
