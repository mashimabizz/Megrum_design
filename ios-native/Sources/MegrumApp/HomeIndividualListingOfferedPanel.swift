import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeIndividualListingOfferedPanel: View {
    var detail: HomeIndividualListingDetailContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("譲るもの")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Divider()

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                if detail.offeredItems.isEmpty {
                    ListingOfferCashCard(amount: detail.offeredCashAmount)
                } else {
                    HomeDiscoveryRotaryCard(
                        goods: displayGoods,
                        goodsCondition: .direct,
                        exchangeCondition: .possible,
                        paymentCondition: .compatible,
                        showsConditionOverlay: false
                    )
                    .frame(height: 150)

                    Text(offerCaption)
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.74))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 214)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 274, alignment: .topLeading)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }

    private var offerCaption: String {
        let count = detail.offeredItems.reduce(0) { $0 + $1.quantity }
        if count > 1 {
            switch detail.offeredLogic {
            case .one:
                return "\(count)点からどれか"
            case .all:
                return "\(count)点セット"
            case .atLeast:
                return "\(detail.offeredMinimumCount)点以上"
            }
        }
        return detail.offeredItems.first?.title ?? "グッズ"
    }

    private var displayGoods: [HomeMockGoods] {
        detail.offeredItems.enumerated().map { index, item in
            HomeMockGoods.from(
                item: GoodsItem(
                    id: item.id,
                    ownerID: Self.fallbackOwnerID,
                    title: item.title,
                    imageURL: item.imageURL,
                    quantity: item.quantity
                ),
                index: index,
                goodsTypes: []
            )
        }
    }

    private static let fallbackOwnerID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
}
