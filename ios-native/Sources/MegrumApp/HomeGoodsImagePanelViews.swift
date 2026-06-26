import MegrumDesign
import SwiftUI

struct HomeGoodsImagePanelRail: View {
    var goods: [HomeMockGoods]
    var selectedIndices: Set<Int>
    var selectedBannerText: String?
    var cardSize: HomeGoodsImagePanelCardSize
    var onSelect: (Int) -> Void

    init(
        goods: [HomeMockGoods],
        selectedIndices: Set<Int>,
        selectedBannerText: String? = nil,
        cardSize: HomeGoodsImagePanelCardSize = .regular,
        onSelect: @escaping (Int) -> Void
    ) {
        self.goods = goods
        self.selectedIndices = selectedIndices
        self.selectedBannerText = selectedBannerText
        self.cardSize = cardSize
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
                    .frame(width: cardSize.width, height: cardSize.height)
                    .accessibilityLabel(goods.title)
                    .accessibilityAddTraits(selectedIndices.contains(index) ? [.isSelected] : [])
                }
            }
            .padding(.trailing, 18)
        }
    }
}

struct HomeGoodsImagePanelCardSize {
    var width: CGFloat
    var height: CGFloat

    static let regular = HomeGoodsImagePanelCardSize(width: 118, height: 144)
    static let compact = HomeGoodsImagePanelCardSize(width: 82, height: 100)
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

struct HomeImagePanelGoodsCard: View {
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
