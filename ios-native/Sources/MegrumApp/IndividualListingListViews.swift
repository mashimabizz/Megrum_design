import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingTopBar: View {
    var title: String
    var accessory: AnyView?

    var body: some View {
        if let accessory {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                accessory
                    .padding(.top, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
                    .padding(.bottom, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .center) {
                Button {} label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 50, height: 50)
                        .background(.white.opacity(0.88), in: Circle())
                        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
                .opacity(0.001)

                Spacer()

                VStack(spacing: 5) {
                    Text("個別募集")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("譲るものごとに条件を見る")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 50, height: 50)
                    .background(.white.opacity(0.88), in: Circle())
                    .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 6)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct IndividualListingsContent: View {
    var headerTitle: String
    var headerAccessory: AnyView?
    var showsHeader = true
    var isLoading: Bool
    var listings: [IndividualListing]
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var viewerID: UUID?
    var onEdit: (IndividualListing) -> Void
    var onAddCondition: (IndividualListing) -> Void
    var onDelete: (IndividualListing) -> Void
    @State private var activeListingID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if showsHeader {
                    IndividualListingTopBar(title: headerTitle, accessory: headerAccessory)
                }

                if isLoading {
                    IndividualListingSkeletons()
                } else if listings.isEmpty {
                    EmptyListingView()
                } else if let activeListing = activeListing(in: listings) {
                    IndividualListingConditionStrip(
                        listings: listings,
                        activeListingID: $activeListingID
                    )

                    IndividualListingDesignCard(
                        listing: activeListing,
                        listingIndex: activeListingIndex(in: listings),
                        listingCount: listings.count,
                        inventoryByID: inventoryByID,
                        wishByID: wishByID,
                        groups: groups,
                        characters: characters,
                        goodsTypes: goodsTypes,
                        canEdit: activeListing.ownerID == viewerID,
                        onEdit: {
                            onEdit(activeListing)
                        },
                        onAddCondition: {
                            onAddCondition(activeListing)
                        },
                        onDelete: {
                            onDelete(activeListing)
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 118)
        }
        .onChange(of: listings.map(\.id), initial: true) { _, ids in
            if let activeListingID, ids.contains(activeListingID) {
                return
            }
            activeListingID = ids.first
        }
    }

    private func activeListing(in listings: [IndividualListing]) -> IndividualListing? {
        if let activeListingID,
           let listing = listings.first(where: { $0.id == activeListingID }) {
            return listing
        }
        return listings.first
    }

    private func activeListingIndex(in listings: [IndividualListing]) -> Int {
        guard let activeListingID,
              let index = listings.firstIndex(where: { $0.id == activeListingID })
        else {
            return 0
        }
        return index
    }
}

private struct IndividualListingSkeletons: View {
    var body: some View {
        VStack(spacing: 22) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(height: 430)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct IndividualListingConditionStrip: View {
    var listings: [IndividualListing]
    @Binding var activeListingID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
                    IndividualListingConditionStripCard(
                        index: index,
                        totalCount: listings.count,
                        isSelected: activeListingID == listing.id
                    ) {
                        withAnimation(.smooth(duration: 0.22)) {
                            activeListingID = listing.id
                        }
                    }
                    .id(listing.id)
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 2)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeListingID)
        .accessibilityLabel("交換条件の切り替え")
    }
}

private struct IndividualListingConditionStripCard: View {
    var index: Int
    var totalCount: Int
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Text("交換条件 \(index + 1)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(index + 1)/\(max(1, totalCount))")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.92) : MegrumTheme.lavender)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .frame(width: 136, height: 74, alignment: .leading)
            .background(
                isSelected ? MegrumTheme.lavender : Color.white.opacity(0.88),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? MegrumTheme.lavender.opacity(0.35) : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.20) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("交換条件\(index + 1)")
        .accessibilityValue(isSelected ? "選択中" : "\(totalCount)件中\(index + 1)件目")
    }
}

struct IndividualListingDesignCard: View {
    var listing: IndividualListing
    var listingIndex: Int
    var listingCount: Int
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var canEdit: Bool
    var onEdit: () -> Void
    var onAddCondition: () -> Void
    var onDelete: () -> Void

    private var haveItems: [GoodsItem] {
        listing.haves.compactMap { inventoryByID[$0.itemID] }
    }

    private var sortedOptions: [IndividualListingWishOption] {
        listing.options.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                IndividualListingReceivePanel(
                    options: sortedOptions,
                    wishByID: wishByID,
                    groups: groups,
                    characters: characters,
                    goodsTypes: goodsTypes,
                    canEdit: canEdit,
                    onAddCondition: onAddCondition
                )
                .frame(maxWidth: .infinity)

                IndividualListingOfferPanel(
                    listing: listing,
                    haveItems: haveItems,
                    goodsTypes: goodsTypes,
                    fallbackCashAmount: sortedOptions.first(where: \.isCashOffer)?.cashAmount
                )
                .frame(maxWidth: .infinity)
            }

            IndividualListingExchangeConditionPanel(
                listing: listing,
                canEdit: canEdit,
                onDelete: onDelete
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("個別募集 交換条件 \(listingIndex + 1)")
    }
}

private struct ListingHeroStack: View {
    var items: [GoodsItem]

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.55, 210)
            let height = min(proxy.size.height, 282)
            let visibleItems = Array(items.prefix(3))

            ZStack {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    ListingGoodsImage(url: item.imageURL, title: item.title)
                        .frame(width: width, height: height)
                        .offset(x: CGFloat(index - 1) * width * 0.48, y: CGFloat(index) * 8)
                        .scaleEffect(index == 0 ? 1 : 0.92)
                        .zIndex(Double(visibleItems.count - index))
                        .opacity(index == 0 ? 1 : 0.78)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension String {
    var shortListingStatusTitle: String {
        switch self {
        case "成立候補あり":
            "成立済"
        default:
            self
        }
    }
}

private struct IndividualListingCard: View {
    var listing: IndividualListing
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var canEdit: Bool = false
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(listing.status.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(statusColor, in: Capsule())

                Spacer()

                if canEdit {
                    Menu {
                        Button(action: onEdit) {
                            Label("編集", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("個別募集を編集")
                }

                Text(listing.haveLogic == .all ? "譲るもの全部" : "どれか譲る")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            HStack(alignment: .top, spacing: 12) {
                ListingItemGroup(
                    title: "譲る",
                    items: listing.haves.map { quantity in
                        ListedItemLabel(
                            title: inventoryByID[quantity.itemID]?.title ?? "グッズ",
                            quantity: quantity.quantity
                        )
                    }
                )

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 30, height: 58)

                ListingItemGroup(
                    title: "求める",
                    items: optionItems
                )
            }

            if let note = listing.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                Text(note)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: 10)
    }

    private var optionItems: [ListedItemLabel] {
        let options = listing.options.sorted(by: { $0.position < $1.position })
        guard !options.isEmpty else {
            return [ListedItemLabel(title: "未設定", quantity: 1)]
        }
        return options.enumerated().flatMap { index, option -> [ListedItemLabel] in
            let prefix = options.count > 1 ? "選択肢\(index + 1) " : ""
            if option.isCashOffer, let amount = option.cashAmount {
                return [ListedItemLabel(title: "\(prefix)定価 \(amount)円", quantity: 1)]
            }
            return option.wishes.map { quantity in
                ListedItemLabel(
                    title: "\(prefix)\(wishByID[quantity.itemID]?.title ?? "Wish")",
                    quantity: quantity.quantity
                )
            }
        }
    }

    private var statusColor: Color {
        switch listing.status {
        case .active:
            MegrumTheme.lavender
        case .paused:
            MegrumTheme.muted
        case .matched:
            MegrumTheme.sky
        case .closed:
            MegrumTheme.ink.opacity(0.55)
        }
    }
}

private struct ListingItemGroup: View {
    var title: String
    var items: [ListedItemLabel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    HStack(spacing: 7) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ListedItemLabel: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var quantity: Int
}

struct EmptyListingView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
            Text("個別募集はまだありません")
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text("マイグッズとWishを選んで、ピンポイントの交換条件を作れます。")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
        }
    }
}

struct AddIndividualListingButton: View {
    var title: String = "募集を追加"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.20), in: Circle())
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
