import MegrumDesign
import SwiftUI

/// 認証系の主アクション（iter1226.406 刷新）：
/// 濃紫の独自グラデをやめ、共通 `MegrumPrimaryButtonStyle`（lavender→sky・radius14）へ統一。
struct AuthPrimaryActionButton: View {
    var title: String
    var isLoading: Bool
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
            }
        }
        .buttonStyle(.megrumPrimary(height: 56))
        .disabled(isLoading || isDisabled)
    }
}
