import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingOptionRow: View {
    var index: Int
    var option: IndividualListingWishOption
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]

    @State private var isShowingGoods = false

    private var wishItems: [WishItem] {
        option.wishes.compactMap { wishByID[$0.itemID] }
    }

    private var usesCollapsedGoods: Bool {
        IndividualListingListPresentation.usesCollapsedGoodsSummary(goodsCount: wishItems.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IndividualListingOptionRowHeader(index: index, logicTitle: logicTitle)

            if usesCollapsedGoods {
                Button {
                    isShowingGoods = true
                } label: {
                    IndividualListingCollapsedGoodsRow(items: wishItems)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("選択肢\(index)のグッズ\(wishItems.count)件を表示")
            } else {
                IndividualListingOptionPreviewContent(
                    isCashOffer: option.isCashOffer,
                    cashAmount: option.cashAmount,
                    wishItems: wishItems,
                    conditionText: conditionText
                )
            }
        }
        .padding(.vertical, 14)
        .sheet(isPresented: $isShowingGoods) {
            IndividualListingOptionGoodsSheet(
                title: IndividualListingListPresentation.optionTitle(index: index),
                items: wishItems
            )
        }
    }

    /// 条件指定型の選択肢をコンパクトな1本の文字列で表す。
    private var conditionText: String {
        var parts: [String] = []
        if let groupName = groupName(for: option.wishGroupID) {
            parts.append(groupName)
        }
        if let goodsTypeName = goodsTypeName(for: option.wishGoodsTypeID) {
            parts.append(goodsTypeName)
        }
        if !option.wishMemberIDs.isEmpty {
            let names = characters
                .filter { option.wishMemberIDs.contains($0.id) }
                .prefix(3)
                .map(\.name)
                .joined(separator: "・")
            let memberText = names.isEmpty ? "メンバー\(option.wishMemberIDs.count)人" : names
            parts.append(option.excludesWishMembers ? "\(memberText)以外" : memberText)
        }
        if !option.wishSeriesNames.isEmpty {
            parts.append(option.wishSeriesNames.map { "#\($0)" }.joined(separator: " "))
        }
        if option.wishQuantity > 1 {
            parts.append("\(option.wishQuantity)点")
        }
        return parts.isEmpty ? "条件指定" : parts.joined(separator: " / ")
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

/// 1つの選択肢内に3枚以上のグッズがある時のまとめ表示。
/// タップでその選択肢のグッズ一覧シートを開く。
private struct IndividualListingCollapsedGoodsRow: View {
    var items: [WishItem]

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                    ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 9)
                        .frame(width: 50, height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(.white, lineWidth: 1.6)
                        }
                        .offset(x: CGFloat(index) * 16)
                }
            }
            .frame(width: 50 + 32, height: 50, alignment: .leading)

            Text("\(items.count)件")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MegrumTheme.muted)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

/// 選択肢1つ分のグッズ一覧シート。
private struct IndividualListingOptionGoodsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var title: String
    var items: [WishItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(items) { item in
                        VStack(spacing: 6) {
                            ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 12)
                                .frame(height: 104)
                                .frame(maxWidth: .infinity)

                            Text(item.title)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct IndividualListingOptionRowHeader: View {
    var index: Int
    var logicTitle: String?

    var body: some View {
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
    }
}

private struct IndividualListingOptionPreviewContent: View {
    var isCashOffer: Bool
    var cashAmount: Int?
    var wishItems: [WishItem]
    var conditionText: String

    var body: some View {
        HStack(spacing: 8) {
            if isCashOffer {
                ListingOptionPriceBadge(amount: cashAmount)
            } else if wishItems.isEmpty {
                Text(conditionText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(wishItems.prefix(2)) { item in
                    ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 9)
                        .frame(width: 50, height: 50)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

