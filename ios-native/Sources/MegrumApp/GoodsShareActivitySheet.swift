#if os(iOS)
import SwiftUI
import UIKit

struct GoodsShareActivitySheet: UIViewControllerRepresentable {
    var payload: GoodsSharePostPayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [payload.text, payload.image],
            applicationActivities: nil
        )
        if let rootView = UIApplication.shared.megrumShareRootView {
            controller.popoverPresentationController?.sourceView = rootView
            controller.popoverPresentationController?.sourceRect = CGRect(
                x: rootView.bounds.midX,
                y: rootView.bounds.midY,
                width: 1,
                height: 1
            )
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension UIApplication {
    var megrumShareRootView: UIView? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .view
    }
}
#endif
