import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDealGoodsPanel: View {
    var offeredItems: [GoodsItem]
    var requestedItems: [GoodsItem]
    var offeredBadgeTitle: String?
    var requestedBadgeTitle: String?
    var offeredTitle: String
    var requestedTitle: String
    var offeredEmptyTitle: String
    var requestedEmptyTitle: String

    init(
        offeredItems: [GoodsItem],
        requestedItems: [GoodsItem],
        offeredBadgeTitle: String? = nil,
        requestedBadgeTitle: String? = nil,
        offeredTitle: String = "譲るグッズ",
        requestedTitle: String = "求めるグッズ",
        offeredEmptyTitle: String = "譲るグッズ未選択",
        requestedEmptyTitle: String = "求めるグッズ未選択"
    ) {
        self.offeredItems = offeredItems
        self.requestedItems = requestedItems
        self.offeredBadgeTitle = offeredBadgeTitle
        self.requestedBadgeTitle = requestedBadgeTitle
        self.offeredTitle = offeredTitle
        self.requestedTitle = requestedTitle
        self.offeredEmptyTitle = offeredEmptyTitle
        self.requestedEmptyTitle = requestedEmptyTitle
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TradeGoodsCarouselColumn(
                title: requestedTitle,
                emptyTitle: requestedEmptyTitle,
                items: requestedItems,
                accentColor: MegrumTheme.lavender,
                badgeTitle: requestedBadgeTitle
            )

            TradeExchangeGlyph()

            TradeGoodsCarouselColumn(
                title: offeredTitle,
                emptyTitle: offeredEmptyTitle,
                items: offeredItems,
                accentColor: MegrumTheme.pink,
                badgeTitle: offeredBadgeTitle
            )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TradeExchangeGlyph: View {
    var body: some View {
        VStack(spacing: -5) {
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
            Image(systemName: "arrow.left")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(MegrumTheme.pink)
        }
        .frame(width: 25)
        .accessibilityHidden(true)
    }
}
