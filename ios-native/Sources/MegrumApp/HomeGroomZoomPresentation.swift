import MegrumCore
import SwiftUI

/// iter1226.448：ホームレールからグルームを開く iOS18 標準 zoom 提示のルート。
/// `sourceID` はタップしたタイル（`matchedTransitionSource(id:)`）と一致させる。
struct HomeGroomZoomRoute: Identifiable {
    let id = UUID()
    /// zoom の source タイルID（代表グルームID or 自分タイルの固定ID）。
    let sourceID: UUID
    /// ビューアで辿るグルーム列（レール全体の一連 or 自分の一連）。
    let grooms: [GroomPost]
    /// 最初に表示するグルーム（最古の未読など）。
    let initial: GroomPost
}

/// ホームレールのグルームを標準 zoom で全画面提示するモディファイア。
///
/// タブ上位の共有オーバーレイ（`meguriGroomViewerPost`）は map / めぐり一覧が使い続けるため
/// 触らず、ホーム経路だけをこのローカルな `fullScreenCover` + `.navigationTransition(.zoom)` に
/// 分離する。これにより「タイルの実矩形から、枠と中身が最初のフレームから一体で連続変形」
/// する開き方になり、手組み scaleEffect 方式の「枠が先に開いて写真が後から違うサイズで来る」
/// ガクつきが構造的に消える。
struct HomeGroomZoomPresentation: ViewModifier {
    @Binding var route: HomeGroomZoomRoute?
    var appState: MegrumAppState?
    var namespace: Namespace.ID
    /// ビューア内でユーザー名をタップした時に開く著者プロフィール。
    var onOpenAuthorProfile: (UUID) -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $route) { route in
            if let appState {
                GroomViewerScreen(
                    grooms: route.grooms,
                    initialGroom: route.initial,
                    appState: appState,
                    onDismiss: { self.route = nil },
                    onOpenMeguriUserProfile: { userID in
                        self.route = nil
                        // 閉じアニメ（zoom-back）と重ならないよう1フレーム待ってから遷移。
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            onOpenAuthorProfile(userID)
                        }
                    }
                )
                .modifier(HomeGroomZoomDestination(sourceID: route.sourceID, namespace: namespace))
            }
        }
        #else
        content
        #endif
    }
}

/// iOS18+ でのみ zoom 遷移を付ける（iOS17 は通常の fullScreenCover 提示）。
private struct HomeGroomZoomDestination: ViewModifier {
    var sourceID: UUID
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
        #else
        content
        #endif
    }
}
