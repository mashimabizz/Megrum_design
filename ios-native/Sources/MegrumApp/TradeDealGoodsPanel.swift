import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDealGoodsPanel: View {
    var offeredItems: [GoodsItem]
    var requestedItems: [GoodsItem]
    var offeredCashOffer: Bool
    var offeredCashAmount: Int?
    var requestedCashOffer: Bool
    var requestedCashAmount: Int?
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
        offeredCashOffer: Bool = false,
        offeredCashAmount: Int? = nil,
        requestedCashOffer: Bool = false,
        requestedCashAmount: Int? = nil,
        offeredBadgeTitle: String? = nil,
        requestedBadgeTitle: String? = nil,
        offeredTitle: String = "譲るグッズ",
        requestedTitle: String = "うけとるグッズ",
        offeredEmptyTitle: String = "譲るグッズ未選択",
        requestedEmptyTitle: String = "うけとるグッズ未選択",
        onCarouselTap: (() -> Void)? = nil
    ) {
        self.offeredItems = offeredItems
        self.requestedItems = requestedItems
        self.offeredCashOffer = offeredCashOffer
        self.offeredCashAmount = offeredCashAmount
        self.requestedCashOffer = requestedCashOffer
        self.requestedCashAmount = requestedCashAmount
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
                cashOffer: requestedCashOffer,
                cashAmount: requestedCashAmount,
                accentColor: MegrumTheme.lavender,
                badgeTitle: requestedBadgeTitle,
                onStageTap: onCarouselTap
            )

            TradeExchangeGlyph()

            TradeGoodsCarouselColumn(
                title: offeredTitle,
                emptyTitle: offeredEmptyTitle,
                items: offeredItems,
                cashOffer: offeredCashOffer,
                cashAmount: offeredCashAmount,
                accentColor: MegrumTheme.pink,
                badgeTitle: offeredBadgeTitle,
                onStageTap: onCarouselTap
            )
        }
        .padding(.horizontal, 1)
        .padding(.vertical, 2)
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
