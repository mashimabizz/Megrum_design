import MegrumDesign
import SwiftUI

extension TradeCardReadState {
    var showsStateBackground: Bool {
        switch self {
        case .unopened:
            true
        case .opened, .waitingForReply:
            false
        }
    }

    var stateBackgroundColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.canvas
        case .opened, .waitingForReply:
            .white
        }
    }

    var stateBorderColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink.opacity(0.14)
        case .opened, .waitingForReply:
            .clear
        }
    }

    var stateColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink
        case .opened:
            MegrumTheme.ink.opacity(0.72)
        case .waitingForReply:
            MegrumTheme.muted.opacity(0.70)
        }
    }

    var handleColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink
        case .opened:
            MegrumTheme.ink.opacity(0.78)
        case .waitingForReply:
            MegrumTheme.muted.opacity(0.78)
        }
    }

    var stateWeight: Font.Weight {
        switch self {
        case .unopened:
            .black
        case .opened:
            .bold
        case .waitingForReply:
            .semibold
        }
    }

    var handleWeight: Font.Weight {
        switch self {
        case .unopened:
            .bold
        case .opened:
            .semibold
        case .waitingForReply:
            .semibold
        }
    }
}
