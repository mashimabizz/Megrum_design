import MegrumCore
import MegrumDesign
import SwiftUI

enum ProfileVisualTab: String, CaseIterable, Identifiable {
    case goods = "譲"
    case listings = "個別募集"
    case wish = "ほしいもの"

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

/// 推しタグの階層。L1（グループ/作品）＝指名ありトーン、L2（メンバー/キャラ）＝wish一致トーン。
enum ProfileVisualTagKind: Hashable {
    case plain
    case group
    case member
}

struct ProfileVisualTagItem: Identifiable, Hashable {
    var title: String
    var colorKey: String
    var kind: ProfileVisualTagKind = .plain

    var id: String {
        "\(colorKey):\(title)"
    }
}

enum ProfileVisualTagSize {
    case regular
    case compact
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
