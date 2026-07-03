import SwiftUI

#if os(iOS)
import UIKit

struct SystemTabBarVisibilityHost: UIViewControllerRepresentable {
    var isHidden: Bool

    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ viewController: Controller, context: Context) {
        viewController.setTabBarHidden(isHidden)
    }

    static func dismantleUIViewController(_ viewController: Controller, coordinator: ()) {
        viewController.setTabBarHidden(false)
    }

    final class Controller: UIViewController {
        private var requestedHiddenState = false

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            applyRequestedHiddenState()
        }

        func setTabBarHidden(_ isHidden: Bool) {
            requestedHiddenState = isHidden
            applyRequestedHiddenState()
        }

        private func applyRequestedHiddenState() {
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                self.nearestTabBarController()?.tabBar.isHidden = self.requestedHiddenState
            }
        }

        private func nearestTabBarController() -> UITabBarController? {
            if let tabBarController {
                return tabBarController
            }
            if let tabBarController = parentTabBarController() {
                return tabBarController
            }
            if let tabBarController = presentingTabBarController() {
                return tabBarController
            }
            return view.window?.rootViewController?.containedTabBarController()
        }

        private func parentTabBarController() -> UITabBarController? {
            var controller = parent
            while let current = controller {
                if let tabBarController = current as? UITabBarController {
                    return tabBarController
                }
                if let tabBarController = current.tabBarController {
                    return tabBarController
                }
                controller = current.parent
            }
            return nil
        }

        private func presentingTabBarController() -> UITabBarController? {
            var controller = presentingViewController
            while let current = controller {
                if let tabBarController = current as? UITabBarController {
                    return tabBarController
                }
                if let tabBarController = current.tabBarController {
                    return tabBarController
                }
                controller = current.presentingViewController
            }
            return nil
        }
    }
}

private extension UIViewController {
    func containedTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        for child in children {
            if let tabBarController = child.containedTabBarController() {
                return tabBarController
            }
        }
        if let presentedViewController,
           let tabBarController = presentedViewController.containedTabBarController() {
            return tabBarController
        }
        return nil
    }
}
#else
struct SystemTabBarVisibilityHost: View {
    var isHidden: Bool

    var body: some View {
        EmptyView()
    }
}
#endif
