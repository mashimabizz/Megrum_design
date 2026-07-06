import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriUserProfileRoute: Identifiable, Equatable {
    var userID: UUID
    var id: UUID { userID }
}

/// グルーム等からユーザーを開いた時のプロフィール。
/// iter1226.298: めぐり用の簡易プロフィールをやめ、常にグッズ交換側のプロフィールを表示する
/// （自分のグルームなら自分の交換プロフィール）。
struct MeguriUserProfileRouteScreen: View {
    @ObservedObject var appState: MegrumAppState
    var userID: UUID
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onClose: () -> Void
    var onOpenMessage: (UUID) -> Void

    var body: some View {
        if appState.viewer?.id == userID {
            OwnProfileScreen(appState: appState, onClose: onClose)
        } else {
            // 各タブ下のバナー広告は不要（オーナーFB iter1226.338）。
            PublicUserProfileScreen(
                appState: appState,
                userID: userID,
                adDisplayContext: adDisplayContext
            )
        }
    }
}
