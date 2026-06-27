import SwiftUI

#if canImport(UIKit)
import UIKit

struct TradeDetailLeadingEdgePanCaptureView: UIViewRepresentable {
    var hitWidth: CGFloat
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> TradeDetailLeadingEdgePanView {
        let view = TradeDetailLeadingEdgePanView(frame: .zero)
        view.hitWidth = hitWidth
        view.backgroundColor = UIColor.black.withAlphaComponent(0.001)
        view.onWindowChanged = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }

        return view
    }

    func updateUIView(_ uiView: TradeDetailLeadingEdgePanView, context: Context) {
        uiView.hitWidth = hitWidth
        context.coordinator.parent = self
    }

    static func dismantleUIView(_ uiView: TradeDetailLeadingEdgePanView, coordinator: Coordinator) {
        coordinator.detach()
        uiView.onWindowChanged = nil
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: TradeDetailLeadingEdgePanCaptureView
        weak var attachedWindow: UIWindow?
        weak var edgePanGesture: UIPanGestureRecognizer?

        init(parent: TradeDetailLeadingEdgePanCaptureView) {
            self.parent = parent
        }

        func attach(to window: UIWindow?) {
            guard attachedWindow !== window else {
                return
            }
            detach()
            guard let window else {
                return
            }

            let edgePanGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleEdgePan(_:))
            )
            edgePanGesture.maximumNumberOfTouches = 1
            edgePanGesture.cancelsTouchesInView = false
            edgePanGesture.delegate = self
            window.addGestureRecognizer(edgePanGesture)
            attachedWindow = window
            self.edgePanGesture = edgePanGesture
        }

        func detach() {
            if let edgePanGesture,
               let gestureView = edgePanGesture.view {
                gestureView.removeGestureRecognizer(edgePanGesture)
            }
            attachedWindow = nil
            edgePanGesture = nil
        }

        @objc func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
            let translationPoint = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            let translation = CGSize(width: translationPoint.x, height: translationPoint.y)
            switch gesture.state {
            case .began, .changed:
                parent.onChanged(translation)
            case .ended:
                parent.onEnded(
                    translation,
                    projectedTranslationWidth(translation.width, velocityX: velocity.x)
                )
            case .cancelled, .failed:
                parent.onEnded(translation, translation.width)
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let gestureView = panGesture.view
            else {
                return true
            }

            let location = panGesture.location(in: gestureView)
            guard location.x <= parent.hitWidth else {
                return false
            }

            let velocity = panGesture.velocity(in: gestureView)
            guard velocity.x > 0 else {
                return false
            }

            return abs(velocity.x) >= abs(velocity.y) * 0.75
        }

        private func projectedTranslationWidth(_ translationWidth: CGFloat, velocityX: CGFloat) -> CGFloat {
            translationWidth + velocityX * 0.18
        }
    }
}

final class TradeDetailLeadingEdgePanView: UIView {
    var hitWidth: CGFloat = 32
    var onWindowChanged: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(window)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        point.x >= 0 && point.x <= hitWidth
    }
}
#else
struct TradeDetailLeadingEdgePanCaptureView: View {
    var hitWidth: CGFloat
    var onChanged: (CGSize) -> Void
    var onEnded: (CGSize, CGFloat) -> Void

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.001))
    }
}
#endif
