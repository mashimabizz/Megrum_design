import MegrumDesign
import SwiftUI

struct TradeUnavailableChatActionSheet: View {
    var action: TradeUnavailableChatAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label(action.title, systemImage: action.systemImage)
        } description: {
            Text(action.description)
        } actions: {
            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(MegrumTheme.lavender)
        }
        .navigationTitle(action.title)
        .megrumInlineNavigationTitle()
    }
}
