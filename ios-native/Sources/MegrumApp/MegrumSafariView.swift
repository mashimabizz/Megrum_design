import SwiftUI

#if os(iOS)
import SafariServices

/// アプリ内ブラウザ（SFSafariViewController）。別アプリに飛ばさず Megrum 内で検索を開く。iter1226.377。
struct MegrumSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(MegrumThemeBridge.lavender)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

/// sheet(item:) 用に URL を Identifiable にする薄いラッパー。
struct MegrumBrowserLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private enum MegrumThemeBridge {
    static let lavender = Color(red: 0.651, green: 0.584, blue: 0.847)
}
