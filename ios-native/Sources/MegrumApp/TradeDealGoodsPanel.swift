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
    var onCarouselTap: (() -> Void)?

    init(
        offeredItems: [GoodsItem],
        requestedItems: [GoodsItem],
        offeredBadgeTitle: String? = nil,
        requestedBadgeTitle: String? = nil,
        offeredTitle: String = "譲るグッズ",
        requestedTitle: String = "求めるグッズ",
        offeredEmptyTitle: String = "譲るグッズ未選択",
        requestedEmptyTitle: String = "求めるグッズ未選択",
        onCarouselTap: (() -> Void)? = nil
    ) {
        self.offeredItems = offeredItems
        self.requestedItems = requestedItems
        self.offeredBadgeTitle = offeredBadgeTitle
        self.requestedBadgeTitle = requestedBadgeTitle
        self.offeredTitle = offeredTitle
        self.requestedTitle = requestedTitle
        self.offeredEmptyTitle = offeredEmptyTitle
        self.requestedEmptyTitle = requestedEmptyTitle
        self.onCarouselTap = onCarouselTap
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            TradeGoodsCarouselColumn(
                title: requestedTitle,
                emptyTitle: requestedEmptyTitle,
                items: requestedItems,
                accentColor: MegrumTheme.lavender,
                badgeTitle: requestedBadgeTitle,
                onStageTap: onCarouselTap
            )

            TradeExchangeGlyph()

            TradeGoodsCarouselColumn(
                title: offeredTitle,
                emptyTitle: offeredEmptyTitle,
                items: offeredItems,
                accentColor: MegrumTheme.pink,
                badgeTitle: offeredBadgeTitle,
                onStageTap: onCarouselTap
            )
        }
        .padding(.horizontal, 1)
        .padding(.vertical, 2)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TradeExchangeGlyph: View {
    var body: some View {
        VStack(spacing: -4) {
            Image(systemName: "arrow.right")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
            Image(systemName: "arrow.left")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(MegrumTheme.pink)
        }
        .frame(width: 21)
        .accessibilityHidden(true)
    }
}
