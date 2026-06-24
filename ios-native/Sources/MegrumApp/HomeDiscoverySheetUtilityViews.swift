import Foundation
import MegrumDesign
import SwiftUI

struct HomeTinyGoodsThumbnail: View {
    var goods: HomeMockGoods

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            HomeGoodsArtwork(goods: goods)
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct HomeOtherExchangeRows<LeadingContent: View>: View {
    var addedCandidateIDs: Set<UUID> = []
    var excludedGoodsIDs: Set<UUID> = []
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var showsLeadingDivider: Bool = false
    private let listingHitPayloadsOverride: [HomeExtraHitPayload]?
    private let wishHitPayloadsOverride: [HomeExtraHitPayload]?
    private let leadingContent: LeadingContent

    init(
        addedCandidateIDs: Set<UUID> = [],
        excludedGoodsIDs: Set<UUID> = [],
        listingHitPayloads: [HomeExtraHitPayload]? = nil,
        wishHitPayloads: [HomeExtraHitPayload]? = nil,
        onOpenNestedSheet: @escaping (HomeDiscoverySheet) -> Void,
        showsLeadingDivider: Bool = false,
        @ViewBuilder leadingContent: () -> LeadingContent
    ) {
        self.addedCandidateIDs = addedCandidateIDs
        self.excludedGoodsIDs = excludedGoodsIDs
        self.onOpenNestedSheet = onOpenNestedSheet
        self.showsLeadingDivider = showsLeadingDivider
        self.listingHitPayloadsOverride = listingHitPayloads
        self.wishHitPayloadsOverride = wishHitPayloads
        self.leadingContent = leadingContent()
    }

    private var listingHitPayloads: [HomeExtraHitPayload] {
        HomeOtherExchangePolicy.visiblePayloads(
            rawListingHitPayloads,
            excluding: excludedGoodsIDs
        )
    }

    private var wishHitPayloads: [HomeExtraHitPayload] {
        HomeOtherExchangePolicy.visibleWishPayloads(
            rawWishHitPayloads,
            excluding: excludedGoodsIDs,
            listingHitPayloads: listingHitPayloads
        )
    }

    private var rawListingHitPayloads: [HomeExtraHitPayload] {
        listingHitPayloadsOverride ?? []
    }

    private var rawWishHitPayloads: [HomeExtraHitPayload] {
        wishHitPayloadsOverride ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("他にも交換できそうなもの")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(alignment: .leading, spacing: 16) {
                leadingContent

                if showsLeadingDivider && (!listingHitPayloads.isEmpty || !wishHitPayloads.isEmpty) {
                    Divider().opacity(0.45)
                }

                if !listingHitPayloads.isEmpty {
                    imageSection(
                        title: "相手の個別募集にヒット",
                        color: MegrumTheme.pink,
                        payloads: listingHitPayloads
                    )
                }

                if !listingHitPayloads.isEmpty && !wishHitPayloads.isEmpty {
                    Divider().opacity(0.45)
                }

                if !wishHitPayloads.isEmpty {
                    imageSection(
                        title: "WishでHit",
                        color: MegrumTheme.sky,
                        payloads: wishHitPayloads
                    )
                }

                if !showsLeadingDivider && listingHitPayloads.isEmpty && wishHitPayloads.isEmpty {
                    HomeOtherExchangeEmptyPanel()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func imageSection(
        title: String,
        color: Color,
        payloads: [HomeExtraHitPayload]
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(color)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(payloads) { payload in
                        HomeOtherExchangeThumbnailButton(
                            goods: payload.goods,
                            selected: addedCandidateIDs.contains(payload.goods.id)
                        ) {
                            onOpenNestedSheet(payload.nestedSheet)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

}

private struct HomeOtherExchangeEmptyPanel: View {
    var body: some View {
        Text(HomeOtherExchangeCopy.noOtherExchangeCandidates)
            .font(.system(size: 13.5, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum HomeOtherExchangeCopy {
    static let noOtherExchangeCandidates = "他に交換できそうなものはありません"
}

extension HomeOtherExchangeRows where LeadingContent == EmptyView {
    init(
        addedCandidateIDs: Set<UUID> = [],
        excludedGoodsIDs: Set<UUID> = [],
        onOpenNestedSheet: @escaping (HomeDiscoverySheet) -> Void
    ) {
        self.init(
            addedCandidateIDs: addedCandidateIDs,
            excludedGoodsIDs: excludedGoodsIDs,
            onOpenNestedSheet: onOpenNestedSheet,
            showsLeadingDivider: false
        ) {
            EmptyView()
        }
    }
}

enum HomeOtherExchangePolicy {
    static func visibleGoods(_ goods: [HomeMockGoods], excluding excludedGoodsIDs: Set<UUID>) -> [HomeMockGoods] {
        guard !excludedGoodsIDs.isEmpty else {
            return goods
        }
        return goods.filter { !excludedGoodsIDs.contains($0.id) }
    }

    static func visiblePayloads(
        _ payloads: [HomeExtraHitPayload],
        excluding excludedGoodsIDs: Set<UUID>
    ) -> [HomeExtraHitPayload] {
        guard !excludedGoodsIDs.isEmpty else {
            return payloads
        }
        return payloads.filter { !excludedGoodsIDs.contains($0.goods.id) }
    }

    static func visibleWishGoods(
        _ goods: [HomeMockGoods],
        excluding excludedGoodsIDs: Set<UUID>,
        listingHitGoods: [HomeMockGoods]
    ) -> [HomeMockGoods] {
        visibleGoods(
            goods,
            excluding: excludedGoodsIDs.union(listingHitGoods.map(\.id))
        )
    }

    static func visibleWishPayloads(
        _ payloads: [HomeExtraHitPayload],
        excluding excludedGoodsIDs: Set<UUID>,
        listingHitPayloads: [HomeExtraHitPayload]
    ) -> [HomeExtraHitPayload] {
        visiblePayloads(
            payloads,
            excluding: excludedGoodsIDs.union(listingHitPayloads.map(\.goods.id))
        )
    }
}

private struct HomeOtherExchangeThumbnailButton: View {
    var goods: HomeMockGoods
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                HomeTinyGoodsThumbnail(goods: goods)
                    .frame(width: 58, height: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(
                                selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                                lineWidth: selected ? 3 : 1
                            )
                    }

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(MegrumTheme.lavender, in: Circle())
                        .offset(x: -5, y: -5)
                        .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
                }
            }
            .padding(3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goods.title)を交換候補として確認")
    }
}

struct HomeExchangeSummaryBox: View {
    var leftTitle: String = "相手の譲るグッズ"
    var rightTitle: String = "あなたが出すグッズ"
    var left: HomeMockGoods
    var right: HomeMockGoods

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSheetSectionTitle(systemName: "arrow.left.arrow.right", title: "追加される交換候補")

            HStack(spacing: 20) {
                summarySide(title: leftTitle, goods: left)
                Image(systemName: "arrow.right")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
                summarySide(title: rightTitle, goods: right)
            }
            .padding(14)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func summarySide(title: String, goods: HomeMockGoods) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HomeTinyGoodsThumbnail(goods: goods)
                .frame(width: 70, height: 62)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HomeFilterChip: View {
    var title: String
    var systemName: String
    var selected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemName)
            Text(title)
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(.white.opacity(0.80), in: Capsule())
        .overlay {
            Capsule()
                .stroke(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.10), lineWidth: selected ? 1.5 : 1)
        }
    }
}

struct HomeWishUserRow: Identifiable {
    var id = UUID()
    var name: String
    var age: Int
    var gender: String
    var rating: String
    var trades: String
    var prefecture: String
    var goods: [HomeMockGoods]

    static let sampleRows: [HomeWishUserRow] = [
        HomeWishUserRow(name: "mii_交換用", age: 24, gender: "女", rating: "4.8", trades: "32件", prefecture: "福岡県", goods: [HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaStand]),
        HomeWishUserRow(name: "yuna_goods", age: 23, gender: "女", rating: "4.9", trades: "58件", prefecture: "東京都", goods: [HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaKeychain]),
        HomeWishUserRow(name: "sana_trade", age: 26, gender: "女", rating: "4.7", trades: "21件", prefecture: "大阪府", goods: [HomeDiscoveryFixtures.momoFanmi, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaStand]),
        HomeWishUserRow(name: "luv_sana", age: 25, gender: "女", rating: "4.6", trades: "16件", prefecture: "愛知県", goods: [HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.plush]),
        HomeWishUserRow(name: "mina_交換", age: 24, gender: "女", rating: "4.8", trades: "44件", prefecture: "兵庫県", goods: [HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaStand])
    ]
}

struct HomeWishUserRowView: View {
    var row: HomeWishUserRow

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: row.name == "mii_交換用" ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(row.name == "mii_交換用" ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))

            HomeAvatar(symbol: String(row.name.prefix(1)).uppercased())
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(row.name)、\(row.age)歳、\(row.gender)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("★ \(row.rating) ｜ 交換\(row.trades)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                HomeConditionPill(title: row.prefecture, color: MegrumTheme.ink.opacity(0.48), compact: true)
            }
            .frame(width: 126, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(row.goods.prefix(3)) { goods in
                    HomeTinyGoodsThumbnail(goods: goods)
                        .frame(width: 40, height: 44)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(10)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(row.name == "mii_交換用" ? MegrumTheme.lavender.opacity(0.48) : MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

struct HomeAvatar: View {
    var symbol: String

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [MegrumTheme.lavender.opacity(0.62), MegrumTheme.pink.opacity(0.54)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(symbol)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().stroke(.white.opacity(0.78), lineWidth: 1.2))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else {
            return [self]
        }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
