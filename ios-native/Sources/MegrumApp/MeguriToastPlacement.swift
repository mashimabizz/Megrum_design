import SwiftUI

enum MeguriToastPlacement {
    case top
    case bottom

    var alignment: Alignment {
        switch self {
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }

    var transition: AnyTransition {
        switch self {
        case .top:
            .move(edge: .top).combined(with: .opacity)
        case .bottom:
            .move(edge: .bottom).combined(with: .opacity)
        }
    }
}
