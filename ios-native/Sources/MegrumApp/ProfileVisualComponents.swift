import MegrumCore
import MegrumDesign
import SwiftUI

enum ProfileVisualTab: String, CaseIterable, Identifiable {
    case goods = "譲"
    case listings = "個別募集"
    case wish = "Wish"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .goods:
            "bag"
        case .listings:
            "bookmark"
        case .wish:
            "heart"
        }
    }
}

struct ProfileVisualGridItem: Identifiable, Hashable {
    var id: UUID
    var title: String
    var imageURL: URL?
    var tags: [GoodsTag]
    var quantity: Int

    init(
        id: UUID,
        title: String,
        imageURL: URL?,
        tags: [GoodsTag] = [],
        quantity: Int = 1
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.tags = tags
        self.quantity = max(1, quantity)
    }

    init(goods: GoodsItem) {
        self.init(
            id: goods.id,
            title: goods.title,
            imageURL: goods.imageURL,
            tags: goods.tags,
            quantity: goods.quantity
        )
    }

    init(wish: WishItem) {
        self.init(
            id: wish.id,
            title: wish.title,
            imageURL: wish.imageURL,
            tags: wish.tags,
            quantity: wish.quantity
        )
    }
}

struct ProfileVisualTagItem: Identifiable, Hashable {
    var title: String
    var colorKey: String

    var id: String {
        "\(colorKey):\(title)"
    }
}

enum ProfileVisualTagSize {
    case regular
    case compact
}

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

struct ProfileVisualTabs: View {
    @Binding var selection: ProfileVisualTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileVisualTab.allCases) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == tab ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.62))
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selection == tab ? MegrumTheme.lavender : .clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(.white.opacity(0.76))
    }
}

struct ProfileVisualAvatar: View {
    var url: URL?
    var fallback: String
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackText
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackText
                }
            }
    }

    private var fallbackText: some View {
        Text(fallback.first.map(String.init) ?? "M")
            .font(.system(size: size * 0.33, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
    }
}
