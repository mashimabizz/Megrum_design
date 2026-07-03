import MegrumDesign
import SwiftUI

struct MeguriUnreadCountBadge: View {
    enum Size {
        case homeInbox
        case threadRow
    }

    var count: Int
    var size: Size

    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(font)
                .foregroundStyle(.white)
                .frame(minWidth: minWidth, minHeight: minHeight)
                .padding(.horizontal, horizontalPadding)
                .background(MegrumTheme.conditionExact, in: Capsule())
                .shadow(color: MegrumTheme.conditionExact.opacity(shadowOpacity), radius: shadowRadius, y: shadowOffset)
                .accessibilityHidden(true)
        }
    }

    private var displayText: String {
        count > 99 ? "99+" : "\(count)"
    }

    private var font: Font {
        switch size {
        case .homeInbox:
            .system(size: 17, weight: .black, design: .rounded)
        case .threadRow:
            .system(size: 11, weight: .black, design: .rounded)
        }
    }

    private var minWidth: CGFloat {
        switch size {
        case .homeInbox:
            36
        case .threadRow:
            22
        }
    }

    private var minHeight: CGFloat {
        switch size {
        case .homeInbox:
            36
        case .threadRow:
            22
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .homeInbox:
            count > 9 ? 8 : 0
        case .threadRow:
            count > 9 ? 5 : 0
        }
    }

    private var shadowOpacity: Double {
        switch size {
        case .homeInbox:
            0.28
        case .threadRow:
            0.16
        }
    }

    private var shadowRadius: CGFloat {
        switch size {
        case .homeInbox:
            8
        case .threadRow:
            4
        }
    }

    private var shadowOffset: CGFloat {
        switch size {
        case .homeInbox:
            3
        case .threadRow:
            1
        }
    }
}
