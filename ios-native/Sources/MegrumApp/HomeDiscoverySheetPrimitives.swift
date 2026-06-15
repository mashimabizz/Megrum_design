import Foundation
import MegrumDesign
import SwiftUI

struct HomeSheetTitle: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(subtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

struct HomeSheetSectionTitle: View {
    var systemName: String
    var title: String
    var subtitle: String?
    var trailing: String?

    init(systemName: String, title: String, subtitle: String? = nil, trailing: String? = nil) {
        self.systemName = systemName
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 9) {
                    Image(systemName: systemName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

enum HomeMiniCardStyle {
    case condition(String)
    case conditionTags(HomeConditionTagSet)
    case chips([String])
}

struct HomeCandidateMiniRail: View {
    var goods: [HomeMockGoods]
    var selectedIndex: Int
    var labels: [String] = []
    var conditionTagSets: [HomeConditionTagSet] = []
    var cardStyle: HomeMiniCardStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(goods.enumerated()), id: \.element.id) { index, goods in
                    HomeSelectableGoodsCard(
                        goods: goods,
                        selected: index == selectedIndex,
                        label: labels.indices.contains(index) ? labels[index] : nil,
                        style: conditionTagSets.indices.contains(index) ? .conditionTags(conditionTagSets[index]) : cardStyle
                    )
                    .frame(width: 118, height: 144)
                }
            }
            .padding(.trailing, 18)
        }
    }
}

struct HomeGoodsImagePanelRail: View {
    var goods: [HomeMockGoods]
    var selectedIndices: Set<Int>
    var selectedBannerText: String?
    var onSelect: (Int) -> Void

    init(
        goods: [HomeMockGoods],
        selectedIndices: Set<Int>,
        selectedBannerText: String? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.goods = goods
        self.selectedIndices = selectedIndices
        self.selectedBannerText = selectedBannerText
        self.onSelect = onSelect
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(goods.enumerated()), id: \.element.id) { index, goods in
                    Button {
                        onSelect(index)
                    } label: {
                        HomeImagePanelGoodsCard(
                            goods: goods,
                            selected: selectedIndices.contains(index),
                            selectedBannerText: selectedBannerText
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: 118, height: 144)
                    .accessibilityLabel(goods.title)
                    .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                }
            }
            .padding(.trailing, 18)
        }
    }
}

struct HomeGoodsImagePanelGrid: View {
    var goods: [HomeMockGoods]
    var selectedIndices: Set<Int>
    var selectedBannerText: String?
    var onSelect: (Int) -> Void

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    init(
        goods: [HomeMockGoods],
        selectedIndices: Set<Int>,
        selectedBannerText: String? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.goods = goods
        self.selectedIndices = selectedIndices
        self.selectedBannerText = selectedBannerText
        self.onSelect = onSelect
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(goods.enumerated()), id: \.element.id) { index, goods in
                Button {
                    onSelect(index)
                } label: {
                    HomeImagePanelGoodsCard(
                        goods: goods,
                        selected: selectedIndices.contains(index),
                        selectedBannerText: selectedBannerText
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(goods.title)
                .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
            }
        }
    }
}

struct HomeGoodsImagePanelPagedGrid: View {
    var goods: [HomeMockGoods]
    var selectedIndices: Set<Int>
    var selectedBannerText: String?
    var onSelect: (Int) -> Void

    private let columnsPerPage = 3
    private let rowsPerPage = 2
    private let spacing: CGFloat = 10

    init(
        goods: [HomeMockGoods],
        selectedIndices: Set<Int>,
        selectedBannerText: String? = nil,
        onSelect: @escaping (Int) -> Void
    ) {
        self.goods = goods
        self.selectedIndices = selectedIndices
        self.selectedBannerText = selectedBannerText
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            let cellSide = max(88, min(112, (proxy.size.width - spacing * CGFloat(columnsPerPage - 1)) / CGFloat(columnsPerPage)))
            let columns = Array(
                repeating: GridItem(.fixed(cellSide), spacing: spacing),
                count: columnsPerPage
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                            ForEach(page, id: \.element.id) { index, goods in
                                Button {
                                    onSelect(index)
                                } label: {
                                    HomeImagePanelGoodsCard(
                                        goods: goods,
                                        selected: selectedIndices.contains(index),
                                        selectedBannerText: selectedBannerText
                                    )
                                    .frame(width: cellSide, height: cellSide)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(goods.title)
                                .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                            }
                        }
                        .frame(width: proxy.size.width, alignment: .leading)
                    }
                }
                .padding(.trailing, 18)
            }
        }
        .frame(height: 234)
    }

    private var pages: [[(offset: Int, element: HomeMockGoods)]] {
        let pageSize = columnsPerPage * rowsPerPage
        return Array(goods.enumerated()).chunked(into: pageSize)
    }
}

struct HomeListingWantedOptionRail: View {
    var options: [HomeIndividualListingWantedOption]
    var selectedIndices: Set<Int>
    var previewGoodsByOptionID: [UUID: HomeMockGoods]
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        onSelect(index)
                    } label: {
                        HomeListingWantedOptionCard(
                            option: option,
                            selected: selectedIndices.contains(index),
                            previewGoods: previewGoodsByOptionID[option.id]
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: 118, height: 144)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                }
            }
            .padding(.trailing, 18)
        }
    }
}

private struct HomeListingWantedOptionCard: View {
    var option: HomeIndividualListingWantedOption
    var selected: Bool
    var previewGoods: HomeMockGoods?

    var body: some View {
        Group {
            if let previewGoods, option.kind == .goods {
                HomeImagePanelGoodsCard(
                    goods: previewGoods,
                    selected: selected,
                    selectedBannerText: nil
                )
            } else {
                optionTextCard
            }
        }
    }

    private var optionTextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 36, height: 36)
                .background(MegrumTheme.lavender.opacity(0.13), in: Circle())

            Spacer(minLength: 4)

            Text(option.title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.74)

            if let subtitle = option.subtitle {
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.5))
                .padding(9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                    lineWidth: selected ? 2.2 : 1
                )
        }
        .shadow(color: .black.opacity(selected ? 0.16 : 0.08), radius: selected ? 12 : 7, y: selected ? 6 : 3)
    }

    private var symbolName: String {
        switch option.kind {
        case .goods:
            "shippingbox.fill"
        case .condition:
            "line.3.horizontal.decrease.circle.fill"
        case .cash:
            "yensign.circle.fill"
        }
    }
}

private struct HomeImagePanelGoodsCard: View {
    var goods: HomeMockGoods
    var selected: Bool
    var selectedBannerText: String?

    var body: some View {
        HomeGoodsArtwork(goods: goods)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topLeading) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(selected ? MegrumTheme.lavender : .white.opacity(0.92))
                    .symbolRenderingMode(.hierarchical)
                    .padding(9)
                    .shadow(color: .black.opacity(0.22), radius: 4, y: 2)
            }
            .overlay(alignment: .bottom) {
                if selected, let selectedBannerText {
                    Text(selectedBannerText)
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(MegrumTheme.lavender.opacity(0.92))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selected ? MegrumTheme.lavender : .white.opacity(0.72),
                        lineWidth: selected ? 2.2 : 1
                    )
            }
            .shadow(color: .black.opacity(selected ? 0.16 : 0.08), radius: selected ? 12 : 7, y: selected ? 6 : 3)
    }
}

struct HomeSelectableGoodsCard: View {
    var goods: HomeMockGoods
    var selected: Bool
    var label: String?
    var style: HomeMiniCardStyle

    var body: some View {
        VStack(spacing: 8) {
            HomeTinyGoodsThumbnail(goods: goods)
                .frame(height: 72)

            if let label {
                Text(label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }

            switch style {
            case .condition(let title):
                HomeConditionPill(title: title, color: MegrumTheme.pink, compact: true)
            case .conditionTags(let tags):
                HomeMiniConditionTagRows(conditionTags: tags)
            case .chips(let chips):
                FlexibleChipRows(chips: chips)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topLeading) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.6))
                .padding(8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: selected ? 1.6 : 1)
        }
    }
}

private struct HomeMiniConditionTagRows: View {
    var conditionTags: HomeConditionTagSet

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                tag(title: conditionTags.goods.floatingTagTitle, color: conditionTags.goods.accent)
                tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
            }
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.accessibilityText)
    }

    private func tag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9.2, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(.white.opacity(0.92), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.28), lineWidth: 1)
            }
    }
}

private struct FlexibleChipRows: View {
    var chips: [String]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(chips.chunked(into: 2).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { chip in
                        HomeConditionPill(
                            title: chip,
                            color: chipColor(chip),
                            compact: true
                        )
                    }
                }
            }
        }
    }

    private func chipColor(_ chip: String) -> Color {
        if chip.contains("提示") || chip.contains("PayPay") || chip.contains("差額") {
            return MegrumTheme.ok
        }
        if chip.contains("状態") || chip.contains("交換") || chip.contains("グッズ") {
            return MegrumTheme.sky
        }
        return MegrumTheme.lavender
    }
}

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

struct HomeOtherExchangeRows: View {
    var addedCandidateIDs: Set<UUID> = []
    var excludedGoodsIDs: Set<UUID> = []
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    private var listingHitGoods: [HomeMockGoods] {
        HomeOtherExchangePolicy.visibleGoods(
            HomeDiscoveryFixtures.otherListingHit,
            excluding: excludedGoodsIDs
        )
    }

    private var wishHitGoods: [HomeMockGoods] {
        HomeOtherExchangePolicy.visibleGoods(
            HomeDiscoveryFixtures.otherWishHit,
            excluding: excludedGoodsIDs
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("他にも交換できそうなもの")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(alignment: .leading, spacing: 16) {
                if !listingHitGoods.isEmpty {
                    imageSection(
                        title: "個別募集でHit",
                        color: MegrumTheme.pink,
                        goods: listingHitGoods,
                        kind: .listing
                    )
                }

                if !listingHitGoods.isEmpty && !wishHitGoods.isEmpty {
                    Divider().opacity(0.45)
                }

                if !wishHitGoods.isEmpty {
                    imageSection(
                        title: "WishでHit",
                        color: MegrumTheme.sky,
                        goods: wishHitGoods,
                        kind: .wish
                    )
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
        goods: [HomeMockGoods],
        kind: HomeExtraHitKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(color)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(goods.enumerated()), id: \.element.id) { index, item in
                        let payload = payload(kind: kind, goods: item, index: index)
                        HomeOtherExchangeThumbnailButton(
                            goods: item,
                            selected: addedCandidateIDs.contains(item.id)
                        ) {
                            onOpenNestedSheet(payload.nestedSheet)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func payload(kind: HomeExtraHitKind, goods: HomeMockGoods, index: Int) -> HomeExtraHitPayload {
        HomeExtraHitPayload(
            kind: kind,
            goods: goods,
            signals: conditionSignals(kind: kind, index: index)
        )
    }

    private func conditionSignals(kind: HomeExtraHitKind, index: Int) -> HomeCandidateConditionSignals {
        switch kind {
        case .listing:
            HomeDiscoveryFixtures.miiListingHitSignals(index: index)
        case .wish:
            HomeCandidateConditionSignalDefaults.possible(index: index)
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else {
            return [self]
        }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
