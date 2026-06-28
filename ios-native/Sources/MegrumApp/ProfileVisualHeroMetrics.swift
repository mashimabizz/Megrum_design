import SwiftUI

enum ProfileVisualHeroDensity {
    case regular
    case compact

    var verticalSpacing: CGFloat {
        switch self {
        case .regular:
            22
        case .compact:
            9
        }
    }

    var avatarInfoSpacing: CGFloat {
        switch self {
        case .regular:
            22
        case .compact:
            12
        }
    }

    var infoSpacing: CGFloat {
        switch self {
        case .regular:
            9
        case .compact:
            3
        }
    }

    var displayNameFontSize: CGFloat {
        switch self {
        case .regular:
            26
        case .compact:
            20
        }
    }

    var handleFontSize: CGFloat {
        switch self {
        case .regular:
            18
        case .compact:
            13
        }
    }

    var bioFontSize: CGFloat {
        switch self {
        case .regular:
            15
        case .compact:
            11.5
        }
    }

    var statRowSpacing: CGFloat {
        switch self {
        case .regular:
            18
        case .compact:
            10
        }
    }

    var statTitleFontSize: CGFloat {
        switch self {
        case .regular:
            14
        case .compact:
            10.5
        }
    }

    var statValueFontSize: CGFloat {
        switch self {
        case .regular:
            21
        case .compact:
            15
        }
    }

    var statIconFontSize: CGFloat {
        switch self {
        case .regular:
            15
        case .compact:
            12
        }
    }

    var statSpacing: CGFloat {
        switch self {
        case .regular:
            5
        case .compact:
            2
        }
    }

    var statDividerHeight: CGFloat {
        switch self {
        case .regular:
            32
        case .compact:
            22
        }
    }

    var statMinWidth: CGFloat {
        switch self {
        case .regular:
            52
        case .compact:
            52
        }
    }

    var actionFontSize: CGFloat {
        switch self {
        case .regular:
            17
        case .compact:
            14.5
        }
    }

    var actionHeight: CGFloat {
        switch self {
        case .regular:
            56
        case .compact:
            44
        }
    }

    var scheduleActionHeight: CGFloat {
        switch self {
        case .regular:
            48
        case .compact:
            38
        }
    }

    var actionCornerRadius: CGFloat {
        switch self {
        case .regular:
            12
        case .compact:
            11
        }
    }
}

enum ProfileVisualCompactHeroMetrics {
    static let contentSpacing: CGFloat = 10
    static let horizontalPadding: CGFloat = 14
    static let topPadding: CGFloat = 12
    static let bottomPadding: CGFloat = 28
    static let avatarSize: CGFloat = 70
}
