import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ListingOfferCashCard: View {
    var amount: Int?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "gift.fill")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(MegrumTheme.lavender, in: Circle())

            Text(priceText)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1.2)
        }
    }

    private var priceText: String {
        TradeAmountFormatter.fixedPrice(amount: amount)
    }
}

struct IndividualListingOptionRow: View {
    var index: Int
    var option: IndividualListingWishOption
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]

    private var wishItems: [WishItem] {
        option.wishes.compactMap { wishByID[$0.itemID] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(IndividualListingListPresentation.optionTitle(index: index))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(height: 28)
                    .background(MegrumTheme.lavender.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer(minLength: 0)

                if let logicTitle {
                    Text(logicTitle)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
            }

            HStack(spacing: 8) {
                if option.isCashOffer {
                    ListingOptionPriceBadge(amount: option.cashAmount)
                } else if wishItems.isEmpty {
                    ListingConditionTokenFlow(tokens: conditionTokens)
                } else {
                    ForEach(wishItems.prefix(2)) { item in
                        ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 9)
                            .frame(width: 50, height: 50)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
    }

    private var conditionTokens: [String] {
        var tokens: [String] = []
        if let groupName = groupName(for: option.wishGroupID) {
            tokens.append(groupName)
        }
        if let goodsTypeName = goodsTypeName(for: option.wishGoodsTypeID) {
            tokens.append(goodsTypeName)
        }
        return tokens.isEmpty ? ["条件指定"] : tokens
    }

    private var logicTitle: String? {
        IndividualListingListPresentation.optionLogicTitle(for: option)
    }

    private func groupName(for id: UUID?) -> String? {
        guard let id else {
            return nil
        }
        return groups.first { $0.id == id }?.name
    }

    private func goodsTypeName(for id: UUID?) -> String? {
        guard let id else {
            return nil
        }
        return goodsTypes.first { $0.id == id }?.name
    }
}

struct IndividualListingEmptyOptionRow: View {
    var body: some View {
        Text("求めるものが未設定です")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
    }
}

private struct ListingOptionPriceBadge: View {
    var amount: Int?

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "yensign")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(MegrumTheme.lavender, in: Circle())

            Text(priceText)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var priceText: String {
        TradeAmountFormatter.fixedPrice(amount: amount)
    }
}

private struct ListingConditionTokenFlow: View {
    var tokens: [String]

    var body: some View {
        FlowLayout(spacing: 7, rowSpacing: 7) {
            ForEach(tokens, id: \.self) { token in
                Text(token)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

struct IndividualListingAddConditionRow: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(MegrumTheme.lavender, in: Circle())

                Text("条件を編集")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 48)
            .background(MegrumTheme.lavender.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("条件を編集")
    }
}
