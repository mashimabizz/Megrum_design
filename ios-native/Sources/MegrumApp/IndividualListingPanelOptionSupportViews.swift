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

struct IndividualListingOptionThumbnail: View {
    var option: IndividualListingWishOption
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]

    private var firstWishItem: WishItem? {
        option.wishes.compactMap { wishByID[$0.itemID] }.first
    }

    var body: some View {
        Group {
            if let firstWishItem {
                ListingGoodsImage(url: firstWishItem.imageURL, title: firstWishItem.title, cornerRadius: 13)
            } else if option.isCashOffer {
                compactSymbolTile(systemImage: "yensign", title: "支払")
            } else {
                compactTextTile(conditionTitle)
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var conditionTitle: String {
        if let groupName = groupName(for: option.wishGroupID) {
            return groupName
        }
        if let goodsTypeName = goodsTypeName(for: option.wishGoodsTypeID) {
            return goodsTypeName
        }
        return "条件"
    }

    private func compactSymbolTile(systemImage: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(MegrumTheme.lavender)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.lavender.opacity(0.11))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    private func compactTextTile(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.66)
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MegrumTheme.sky.opacity(0.16))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
            }
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

struct IndividualListingOtherOptionsThumbnail: View {
    var body: some View {
        Text("他")
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(width: 58, height: 58)
            .background(MegrumTheme.lavender.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
            }
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
