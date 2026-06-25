import MegrumDesign
import SwiftUI

extension TradeCardReadState {
    var showsStateBackground: Bool {
        switch self {
        case .unopened, .opened:
            true
        case .waitingForReply:
            false
        }
    }

    var stateBackgroundColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink.opacity(0.09)
        case .opened:
            MegrumTheme.ink.opacity(0.055)
        case .waitingForReply:
            .clear
        }
    }

    var stateBorderColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink.opacity(0.14)
        case .opened:
            MegrumTheme.ink.opacity(0.10)
        case .waitingForReply:
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
