import SwiftUI

#if os(iOS)
import UIKit
#endif

/// `ignoresSafeArea` 済みの階層内などで GeometryReader が safe area を
/// 返せない場合に、ウィンドウ実測の上端インセットを取得するための補助。
@MainActor
enum MegrumWindowInsets {
    static var top: CGFloat {
        #if os(iOS)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 59
        #else
        0
        #endif
    }
}
