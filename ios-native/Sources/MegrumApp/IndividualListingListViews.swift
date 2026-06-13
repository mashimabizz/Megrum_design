import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingTopBar: View {
    var accessory: AnyView?

    var body: some View {
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
            .opacity(accessory == nil ? 0.001 : 1)

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

            if let accessory {
                accessory
                    .frame(width: 50, height: 50)
            } else {
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

struct IndividualListingStatusTabs: View {
    @Binding var selectedStatus: IndividualListingStatus
    var counts: [IndividualListingStatus: Int]

    private let visibleStatuses: [IndividualListingStatus] = [.active, .paused, .matched]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(visibleStatuses) { status in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        selectedStatus = status
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(status.displayName.shortListingStatusTitle)
                        Text("\(counts[status, default: 0])")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(selectedStatus == status ? MegrumTheme.lavender : MegrumTheme.muted)
                            .frame(minWidth: 27, minHeight: 27)
                            .background(selectedStatus == status ? .white.opacity(0.86) : MegrumTheme.ink.opacity(0.06), in: Circle())
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(selectedStatus == status ? .white : MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        if selectedStatus == status {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(MegrumTheme.lavender)
                                .shadow(color: MegrumTheme.lavender.opacity(0.24), radius: 12, y: 6)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
        }
    }
}

struct IndividualListingsContent: View {
    var headerAccessory: AnyView?
    @Binding var selectedStatus: IndividualListingStatus
    var listingCountsByStatus: [IndividualListingStatus: Int]
    var isLoading: Bool
    var listings: [IndividualListing]
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var viewerID: UUID?
    var onEdit: (IndividualListing) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IndividualListingTopBar(accessory: headerAccessory)

                IndividualListingStatusTabs(
                    selectedStatus: $selectedStatus,
                    counts: listingCountsByStatus
                )

                if isLoading {
                    IndividualListingSkeletons()
                } else if listings.isEmpty {
                    EmptyListingView()
                } else {
                    VStack(spacing: 26) {
                        ForEach(listings) { listing in
                            IndividualListingDesignCard(
                                listing: listing,
                                inventoryByID: inventoryByID,
                                wishByID: wishByID,
                                canEdit: listing.ownerID == viewerID,
                                onEdit: {
                                    onEdit(listing)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 118)
        }
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

struct IndividualListingDesignCard: View {
    var listing: IndividualListing
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var canEdit: Bool
    var onEdit: () -> Void

    private var haveItems: [GoodsItem] {
        listing.haves.compactMap { inventoryByID[$0.itemID] }
    }

    private var heroItem: GoodsItem? {
        haveItems.first
    }

    private var sortedOptions: [IndividualListingWishOption] {
        listing.options.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .bottom) {
                ListingHeroStack(items: haveItems)
                    .frame(height: 300)

                VStack(spacing: 8) {
                    ListingPageDots(count: max(1, min(haveItems.count, 3)), activeIndex: 0)
                    Text(heroItem?.title ?? "グッズ")
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                }
                .offset(y: 62)
            }
            .padding(.bottom, 68)

            Text("このグッズで受け取れる候補")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 0) {
                ForEach(Array(sortedOptions.prefix(3).enumerated()), id: \.element.id) { index, option in
                    IndividualListingOptionRow(
                        index: index + 1,
                        option: option,
                        wishByID: wishByID
                    )
                    if index < min(sortedOptions.count, 3) - 1 {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
                if sortedOptions.isEmpty {
                    IndividualListingEmptyOptionRow()
                }
            }
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
            }

            HStack(spacing: 18) {
                Button(action: onEdit) {
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.white)
                        .frame(width: 82, height: 82)
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.lavender.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)
                .opacity(canEdit ? 1 : 0.42)

                Text("条件を追加")
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Toggle("それ以外の打診も受け付ける", isOn: .constant(true))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .tint(MegrumTheme.lavender)
                .disabled(true)
        }
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

struct ListingGoodsImage: View {
    var url: URL?
    var title: String
    var cornerRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.16))
            .overlay {
                if let url {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case let .success(image):
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        case .failure:
                            ListingGoodsFallback(title: title)
                        default:
                            ProgressView()
                                .tint(MegrumTheme.lavender)
                        }
                    }
                } else {
                    ListingGoodsFallback(title: title)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.82), lineWidth: 2)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 18, y: 10)
    }
}

private struct ListingGoodsFallback: View {
    var title: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.75), MegrumTheme.sky.opacity(0.66), MegrumTheme.pink.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(title.first.map(String.init) ?? "M")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct ListingPageDots: View {
    var count: Int
    var activeIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<max(1, count), id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.28))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

private struct IndividualListingOptionRow: View {
    var index: Int
    var option: IndividualListingWishOption
    var wishByID: [UUID: WishItem]

    private var wishItems: [WishItem] {
        option.wishes.compactMap { wishByID[$0.itemID] }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("選択肢 \(index)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(MegrumTheme.lavender.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 8) {
                if option.isCashOffer {
                    Text(option.cashAmount.map { "定価 ¥\(NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal))" } ?? "定価")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                } else if wishItems.isEmpty {
                    Text(option.conditionSummary)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                } else {
                    ForEach(wishItems.prefix(2)) { item in
                        ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 9)
                            .frame(width: 48, height: 48)
                    }
                    Text(optionTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(option.isCashOffer ? "定価" : "条件◎")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(option.isCashOffer ? MegrumTheme.ink.opacity(0.70) : MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(MegrumTheme.lavender.opacity(option.isCashOffer ? 0.08 : 0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var optionTitle: String {
        if wishItems.isEmpty {
            return option.conditionSummary
        }
        let names = wishItems.prefix(2).map(\.title).joined(separator: " + ")
        return option.wishes.reduce(0) { $0 + $1.quantity } > 1 ? "\(names)" : names
    }
}

private struct IndividualListingEmptyOptionRow: View {
    var body: some View {
        Text("受け取れる候補が未設定です")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
    }
}

private extension IndividualListingWishOption {
    var conditionSummary: String {
        if isCashOffer {
            return cashAmount.map { "定価 ¥\(NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal))" } ?? "定価"
        }
        var parts: [String] = []
        if wishGroupID != nil {
            parts.append("グループ指定")
        }
        if wishGoodsTypeID != nil {
            parts.append("種別指定")
        }
        return parts.isEmpty ? "画像なし条件" : parts.joined(separator: " / ")
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
    var title: String = "個別募集を作成"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                Text(title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
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
        .accessibilityLabel("個別募集を作成")
    }
}
