import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCollectionScreen: View {
    var title: String
    var subtitle: String
    var items: [GoodsItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenTitle(title: title, subtitle: subtitle)
                GoodsGrid(items: items)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 92)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]

    private var goodsLikeItems: [GoodsItem] {
        items.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                tags: $0.tags
            )
        }
    }

    var body: some View {
        GoodsCollectionScreen(
            title: "Wish",
            subtitle: "ほしいグッズ",
            items: goodsLikeItems
        )
    }
}

struct ScreenTitle: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(subtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
