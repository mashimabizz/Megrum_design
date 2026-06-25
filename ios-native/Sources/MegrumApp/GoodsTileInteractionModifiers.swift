import SwiftUI

struct GoodsTileContextMenuModifier: ViewModifier {
    var isEnabled: Bool
    var primaryActions: [GoodsTileAction]
    var destructiveActions: [GoodsTileAction]
    var onAction: (GoodsTileAction) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.contextMenu {
                ForEach(primaryActions) { action in
                    Button(role: action.role) {
                        onAction(action)
                    } label: {
                        Label(action.title, systemImage: action.symbolName)
                    }
                }
                if !destructiveActions.isEmpty {
                    Divider()
                    ForEach(destructiveActions) { action in
                        Button(role: action.role) {
                            onAction(action)
                        } label: {
                            Label(action.title, systemImage: action.symbolName)
                        }
                    }
                }
            }
        } else {
            content
        }
    }
}

struct GoodsTileExclusivePressModifier: ViewModifier {
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let onLongPress {
            content.gesture(
                ExclusiveGesture(
                    LongPressGesture(minimumDuration: 0.45, maximumDistance: 18),
                    TapGesture()
                )
                .onEnded { value in
                    switch value {
                    case .first(true):
                        MegrumHaptics.longPress()
                        onLongPress()
                    case .second:
                        onTap()
                    case .first(false):
                        break
                    }
                }
            )
        } else {
            content.onTapGesture(perform: onTap)
        }
    }
}
