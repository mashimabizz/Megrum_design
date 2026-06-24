import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingHavesStep: View {
    enum Tab: String {
        case goods
        case cash
    }

    var inventory: [GoodsItem]
    var selectedIDs: Set<UUID>
    @Binding var filter: IndividualListingSelectionFilter
    var groups: [OshiGroup]
    var goodsTypes: [GoodsType]
    @Binding var selectedTab: Tab
    @Binding var cashPricingMode: IndividualListingCashPricingMode
    @Binding var cashAmount: Int
    var onToggle: (GoodsItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IndividualListingStepTitle(step: .haves)

            IndividualListingHaveTabs(selection: $selectedTab)

            switch selectedTab {
            case .goods:
                goodsSelection
            case .cash:
                IndividualListingCashTab(
                    pricingMode: $cashPricingMode,
                    amount: $cashAmount
                )
            }
        }
    }

    private var goodsSelection: some View {
        VStack(alignment: .leading, spacing: 18) {
            IndividualListingSelectionSearchAndFilterBar(
                filter: $filter,
                searchPlaceholder: "グッズを検索",
                groups: availableGroups,
                goodsTypes: availableGoodsTypes,
                tagNames: availableTagNames
            )

            if filteredInventory.isEmpty {
                IndividualListingSelectionEmptyMessage(filterIsActive: filter.isActive)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredInventory) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            ListingSquareSelectableImageTile(
                                imageURL: item.imageURL,
                                title: item.title,
                                isSelected: selectedIDs.contains(item.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.title)を譲るものに選択")
                        .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var filteredInventory: [GoodsItem] {
        inventory.filter(filter.matches)
    }

    private var availableGroups: [OshiGroup] {
        IndividualListingSelectionFilterChoices.groups(items: inventory, allGroups: groups)
    }

    private var availableGoodsTypes: [GoodsType] {
        IndividualListingSelectionFilterChoices.goodsTypes(items: inventory, allGoodsTypes: goodsTypes)
    }

    private var availableTagNames: [String] {
        IndividualListingSelectionFilterChoices.tagNames(items: inventory, filter: filter)
    }

}

struct IndividualListingHaveTabs: View {
    @Binding var selection: IndividualListingHavesStep.Tab

    var body: some View {
        HStack(spacing: 8) {
            tabButton(.goods, title: IndividualListingHaveOfferKind.goods.title)
            tabButton(.cash, title: IndividualListingHaveOfferKind.cash.title)
        }
        .padding(4)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    private func tabButton(_ tab: IndividualListingHavesStep.Tab, title: String) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) {
                selection = tab
            }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(selection == tab ? .white : MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    if selection == tab {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(MegrumTheme.lavender)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct IndividualListingCashAmountCard: View {
    @Binding var amount: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("金額")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }

                Spacer()

                amountField
            }
            .padding(.horizontal, 20)
            .frame(height: 92)
        }
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var amountField: some View {
        let field = TextField("入力…", value: $amount, format: .number)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 22, weight: .regular, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(width: 136, height: 56)
            .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.12), lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                Text("¥")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.68))
                    .padding(.leading, 14)
            }

        #if os(iOS)
        field.keyboardType(.numberPad)
        #else
        field
        #endif
    }
}

private struct ListingSquareSelectableImageTile: View {
    var imageURL: URL?
    var title: String
    var isSelected: Bool

    var body: some View {
        ListingGoodsImage(url: imageURL, title: title, cornerRadius: 12)
            .aspectRatio(1, contentMode: .fit)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .opacity(isSelected ? 1 : 0)
                    .padding(7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
    }
}

struct IndividualListingSelectionEmptyMessage: View {
    var filterIsActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: filterIsActive ? "line.3.horizontal.decrease.circle" : "shippingbox")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
            Text(filterIsActive ? "条件に合うグッズがありません" : "選べるグッズがありません")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
