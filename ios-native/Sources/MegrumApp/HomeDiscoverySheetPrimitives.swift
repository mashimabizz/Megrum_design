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
    var isSelectionEnabled: Bool = true
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    if isSelectionEnabled {
                        Button {
                            onSelect(index)
                        } label: {
                            optionCard(option: option, index: index)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                    } else {
                        optionCard(option: option, index: index)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(option.title)
                    }
                }
            }
            .padding(.trailing, 18)
        }
    }

    private func optionCard(option: HomeIndividualListingWantedOption, index: Int) -> some View {
        HomeListingWantedOptionCard(
            option: option,
            selected: selectedIndices.contains(index),
            previewGoods: previewGoodsByOptionID[option.id],
            showsSelectionIndicator: isSelectionEnabled
        )
        .frame(width: 118, height: 144)
    }
}

private struct HomeListingWantedOptionCard: View {
    var option: HomeIndividualListingWantedOption
    var selected: Bool
    var previewGoods: HomeMockGoods?
    var showsSelectionIndicator: Bool

    var body: some View {
        Group {
            if let previewGoods {
                imageOptionCard(previewGoods)
            } else {
                optionTextCard
            }
        }
    }

    private func imageOptionCard(_ previewGoods: HomeMockGoods) -> some View {
        HomeImagePanelGoodsCard(
            goods: previewGoods,
            selected: selected,
            selectedBannerText: nil,
            showsSelectionIndicator: showsSelectionIndicator
        )
        .overlay(alignment: .topTrailing) {
            if option.kind != .goods {
                optionKindBadge
                    .padding(8)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let subtitle = option.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.54)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var optionTextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 24)

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
            if showsSelectionIndicator {
                selectionBadge
                    .padding(9)
            }
        }
        .overlay(alignment: .topTrailing) {
            optionKindBadge
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

    private var selectionBadge: some View {
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(selected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.5))
    }

    private var optionKindBadge: some View {
        Image(systemName: symbolName)
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(MegrumTheme.lavender)
            .frame(width: 32, height: 32)
            .background(MegrumTheme.lavender.opacity(0.13), in: Circle())
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
    var showsSelectionIndicator: Bool = true

    var body: some View {
        HomeGoodsArtwork(goods: goods)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topLeading) {
                if showsSelectionIndicator {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(selected ? MegrumTheme.lavender : .white.opacity(0.92))
                        .symbolRenderingMode(.hierarchical)
                        .padding(9)
                        .shadow(color: .black.opacity(0.22), radius: 4, y: 2)
                }
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
                if conditionTags.homeCandidateShowsExchangeTag {
                    tag(title: conditionTags.exchange.floatingTagTitle, color: conditionTags.exchange.accent)
                }
            }
            tag(title: conditionTags.payment.floatingTagTitle, color: conditionTags.payment.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(conditionTags.homeCandidateAccessibilityText)
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
