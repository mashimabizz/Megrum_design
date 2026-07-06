import CoreGraphics
import SwiftUI

#if canImport(UIKit)
import UIKit

struct ScrollFriendlyHorizontalPanView: UIViewRepresentable {
    var isPanEnabled: Bool
    var onTap: ((CGPoint) -> Void)?
    /// true にするとオーバーレイ自体はタッチを受けず（下のボタンが押せる）、
    /// パン認識だけを親ビュー経由で拾う。カード全面に重ねる用途向け。
    var passesTouchesThrough: Bool = false
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = passesTouchesThrough
            ? PassthroughPanHostView(coordinator: context.coordinator)
            : UIView(frame: .zero)
        view.backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = context.coordinator
        context.coordinator.panGesture = panGesture
        context.coordinator.usesPassthroughHost = passesTouchesThrough

        if passesTouchesThrough {
            view.isUserInteractionEnabled = false
            (view as? PassthroughPanHostView)?.panGesture = panGesture
        } else {
            view.addGestureRecognizer(panGesture)

            let tapGesture = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            )
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
            context.coordinator.tapGesture = tapGesture
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    /// タッチは透過しつつ、親ビューに付け替えたパンで横スワイプだけ拾うホスト。
    final class PassthroughPanHostView: UIView {
        weak var coordinator: Coordinator?
        var panGesture: UIPanGestureRecognizer?
        private weak var attachedSuperview: UIView?

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            guard let panGesture else {
                return
            }
            attachedSuperview?.removeGestureRecognizer(panGesture)
            attachedSuperview = nil
            if let superview {
                superview.addGestureRecognizer(panGesture)
                attachedSuperview = superview
                coordinator?.passthroughBoundsView = self
            }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ScrollFriendlyHorizontalPanView
        weak var panGesture: UIPanGestureRecognizer?
        weak var tapGesture: UITapGestureRecognizer?
        var usesPassthroughHost = false
        weak var passthroughBoundsView: UIView?

        init(parent: ScrollFriendlyHorizontalPanView) {
            self.parent = parent
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translationSize(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            switch gesture.state {
            case .began, .changed:
                parent.onChanged(translation)
            case .ended:
                parent.onEnded(translation, projectedTranslationWidth(translation.width, velocityX: velocity.x))
            case .cancelled, .failed:
                parent.onEnded(translation, translation.width)
            default:
                break
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else {
                return
            }
            parent.onTap?(gesture.location(in: gesture.view))
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === panGesture {
                guard parent.isPanEnabled, let panGesture else {
                    return false
                }
                if usesPassthroughHost {
                    // 親に付け替えているため、開始位置がオーバーレイの範囲内の時だけ反応する
                    guard let boundsView = passthroughBoundsView,
                          boundsView.bounds.contains(panGesture.location(in: boundsView))
                    else {
                        return false
                    }
                }
                let translation = panGesture.translationSize(in: panGesture.view)
                let velocity = panGesture.velocity(in: panGesture.view)
                let absVelocityX = abs(velocity.x)
                let absVelocityY = abs(velocity.y)
                let hasHorizontalVelocity = absVelocityX > absVelocityY * HorizontalSwipeIntentResolver.horizontalDominanceRatio
                return hasHorizontalVelocity || HorizontalSwipeIntentResolver.isHorizontalSwipe(translation)
            }
            return true
        }

        private func projectedTranslationWidth(_ translationWidth: CGFloat, velocityX: CGFloat) -> CGFloat {
            translationWidth + velocityX * 0.18
        }
    }
}

private extension UIPanGestureRecognizer {
    func translationSize(in view: UIView?) -> CGSize {
        let point = translation(in: view)
        return CGSize(width: point.x, height: point.y)
    }
}
#endif
