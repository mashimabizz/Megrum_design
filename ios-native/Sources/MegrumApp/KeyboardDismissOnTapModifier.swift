import SwiftUI

extension View {
    func dismissKeyboardOnNonInputTap() -> some View {
#if os(iOS)
        modifier(KeyboardDismissOnTapModifier())
#else
        self
#endif
    }
}

#if os(iOS)
import UIKit

private struct KeyboardDismissOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(KeyboardDismissTapInstaller())
    }
}

private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeCoordinator() -> KeyboardDismissTapCoordinator {
        KeyboardDismissTapCoordinator()
    }

    func makeUIView(context: Context) -> KeyboardDismissTapHostView {
        let view = KeyboardDismissTapHostView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: KeyboardDismissTapHostView, context: Context) {
        uiView.coordinator = context.coordinator
        uiView.installIfNeeded()
    }

    static func dismantleUIView(_ uiView: KeyboardDismissTapHostView, coordinator: KeyboardDismissTapCoordinator) {
        uiView.uninstall()
    }
}

private final class KeyboardDismissTapCoordinator: NSObject, UIGestureRecognizerDelegate {
    weak var recognizer: UITapGestureRecognizer?

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }
        recognizer.view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }
        return !touchedView.isEditableTextInputInResponderChain
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private final class KeyboardDismissTapHostView: UIView {
    weak var coordinator: KeyboardDismissTapCoordinator?
    private weak var installedWindow: UIWindow?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installIfNeeded()
    }

    func installIfNeeded() {
        guard let window, let coordinator else {
            return
        }
        guard installedWindow !== window || coordinator.recognizer?.view !== window else {
            return
        }

        uninstall()
        let recognizer = UITapGestureRecognizer(target: coordinator, action: #selector(KeyboardDismissTapCoordinator.handleTap(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = coordinator
        window.addGestureRecognizer(recognizer)
        coordinator.recognizer = recognizer
        installedWindow = window
    }

    func uninstall() {
        if let recognizer = coordinator?.recognizer {
            recognizer.view?.removeGestureRecognizer(recognizer)
            coordinator?.recognizer = nil
        }
        installedWindow = nil
    }

    deinit {
        uninstall()
    }
}

private extension UIView {
    var isEditableTextInputInResponderChain: Bool {
        var current: UIView? = self
        while let view = current {
            if view is UITextField || view is UITextView {
                return true
            }
            current = view.superview
        }
        return false
    }
}
#endif
