import SwiftUI

struct MegrumInAppBrowserRoute: Identifiable {
    let url: URL

    var id: String { url.absoluteString }
}

#if os(iOS)
import SafariServices

/// In-app browser (SFSafariViewController) so web lookups like Google Lens
/// open inside the app instead of bouncing to the external browser.
struct MegrumInAppSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
#endif
