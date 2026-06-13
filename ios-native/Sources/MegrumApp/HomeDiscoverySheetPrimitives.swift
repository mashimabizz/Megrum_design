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
    case chips([String])
}

struct HomeCandidateMiniRail: View {
    var goods: [HomeMockGoods]
    var selectedIndex: Int
    var labels: [String] = []
    var cardStyle: HomeMiniCardStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(goods.enumerated()), id: \.element.id) { index, goods in
                    HomeSelectableGoodsCard(
                        goods: goods,
                        selected: index == selectedIndex,
                        label: labels.indices.contains(index) ? labels[index] : nil,
                        style: cardStyle
                    )
                    .frame(width: 118, height: 144)
                }
            }
            .padding(.trailing, 18)
        }
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
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("他にも交換できそうなもの")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 0) {
                row(
                    title: "個別募集でHit",
                    color: MegrumTheme.pink,
                    goods: HomeDiscoveryFixtures.otherListingHit,
                    sheet: .extraListingHit
                )

                Divider().opacity(0.45)

                row(
                    title: "WishでHit",
                    color: MegrumTheme.sky,
                    goods: HomeDiscoveryFixtures.otherWishHit,
                    sheet: .extraWishHit
                )
            }
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private func row(title: String, color: Color, goods: [HomeMockGoods], sheet: HomeDiscoverySheet) -> some View {
        Button {
            onOpenNestedSheet(sheet)
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .frame(width: 118, alignment: .leading)

                HStack(spacing: 9) {
                    ForEach(goods.prefix(4)) { item in
                        HomeTinyGoodsThumbnail(goods: item)
                            .frame(width: 46, height: 46)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
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
