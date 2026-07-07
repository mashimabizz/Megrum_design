import Foundation
import MegrumDesign
import SwiftUI

/// 取引ブロック（3列：受け取る｜相手希望｜譲る）。notes/19 候補シート再設計・iter1226.374。
/// 相手希望は表示専用（選択肢ピルで切替）。操作するのは「ゆずる」列（＋受け取り選択がある時のみ受け取る列）。
struct HomeDealBlockView: View {
    var model: HomeDealBlockModel
    var onToggleReceive: (Int) -> Void
    var onToggleOffer: (Int) -> Void

    private let thumbSide: CGFloat = 58

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                dealColumn(title: "うけとる", qty: model.receive.qtyLabel) {
                    receiveColumn
                }
                dealColumn(title: "相手希望", qty: nil) {
                    partnerColumn
                }
                dealColumn(title: "ゆずる", qty: model.offer.qtyLabel) {
                    offerColumn
                }
            }

            if let achievement = model.achievement {
                HomeDealAchievementBar(achievement: achievement)
            }
        }
        .padding(14)
        .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - 受け取る

    private var receiveColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.receive.cells) { cell in
                HomeDealThumb(
                    cell: cell,
                    side: thumbSide,
                    onTap: model.receive.selectable ? { onToggleReceive(cell.index) } : nil
                )
            }
        }
    }

    // MARK: - 相手希望

    @ViewBuilder
    private var partnerColumn: some View {
        switch model.partner.kind {
        case .goods:
            VStack(alignment: .leading, spacing: 8) {
                if model.partner.namedItems.isEmpty {
                    HomeDealEmptyCell(side: thumbSide, label: "相手希望")
                } else {
                    ForEach(model.partner.namedItems) { item in
                        HomeDealWishThumb(item: item, side: thumbSide)
                    }
                }
            }
        case .condition:
            if let tile = model.partner.conditionTile {
                HomeDealConditionTileView(tile: tile)
            }
        case .cash:
            EmptyView()
        }
    }

    // MARK: - ゆずる

    @ViewBuilder
    private var offerColumn: some View {
        if model.offer.isNamed {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.offer.rows) { row in
                    offerRow(row)
                }
            }
        } else {
            let cells = model.offer.rows.first?.cells ?? []
            VStack(alignment: .leading, spacing: 8) {
                if cells.isEmpty {
                    HomeDealEmptyCell(side: thumbSide, label: "候補なし")
                } else {
                    ForEach(cells) { cell in
                        HomeDealThumb(cell: cell, side: thumbSide, onTap: { onToggleOffer(cell.index) })
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func offerRow(_ row: HomeDealOfferRow) -> some View {
        if row.cells.isEmpty {
            HomeDealEmptyCell(side: thumbSide, label: "候補なし")
        } else if row.cells.count == 1, let cell = row.cells.first {
            HomeDealThumb(cell: cell, side: thumbSide, onTap: { onToggleOffer(cell.index) })
        } else {
            // 相手のほしいもの1件に対して複数候補 → 横スクロールで切り替え選択。
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(row.cells) { cell in
                        HomeDealThumb(cell: cell, side: thumbSide - 6, onTap: { onToggleOffer(cell.index) })
                    }
                }
            }
        }
    }

    // MARK: - 列の器

    private func dealColumn<Content: View>(
        title: String,
        qty: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(title)
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                if let qty {
                    Text("(\(qty))")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 選択式サムネ（ゆずる・受け取る）。選択済み＝水色→紫グラデチェック、未選択＝破線＋。
struct HomeDealThumb: View {
    var cell: HomeDealGoodsCell
    var side: CGFloat
    /// nil のとき非選択（受け取る自動確定分）。
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { thumb }
                    .buttonStyle(.plain)
            } else {
                thumb
            }
        }
        .accessibilityLabel(cell.title)
        .accessibilityAddTraits(cell.selected ? [.isSelected] : [])
    }

    private var thumb: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                ListingGoodsImage(url: cell.imageURL, title: cell.title, cornerRadius: 12)
                    .frame(width: side, height: side)
                indicator
                    .padding(4)
                if cell.tentative {
                    Text("?")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(MegrumTheme.conditionExact.opacity(0.9), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(4)
                }
            }
            .frame(width: side, height: side)

            Text(cell.title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.7))
                .lineLimit(1)
                .frame(width: side)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        if cell.selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(HomeDealGradient.selection)
                .background(Circle().fill(.white).padding(2))
                .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
        } else if onTap != nil {
            ZStack {
                Circle()
                    .strokeBorder(
                        MegrumTheme.ink.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.6, dash: [3, 2.4])
                    )
                    .background(Circle().fill(.white.opacity(0.86)))
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.42))
            }
            .frame(width: 19, height: 19)
        }
    }
}

/// 相手のほしいもの画像（相手希望・指名）。選択なし表示専用。
struct HomeDealWishThumb: View {
    var item: HomeDealWishCell
    var side: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 12)
                .frame(width: side, height: side)
            Text(item.title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.7))
                .lineLimit(1)
                .frame(width: side)
        }
        .accessibilityLabel("相手のほしいもの \(item.title)")
    }
}

/// 条件タイル（相手希望・条件指定）。スライダーアイコン＋不確定なら「?」＋条件文。
struct HomeDealConditionTileView: View {
    var tile: HomeDealConditionTile

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .heavy))
                Text(tile.tentative ? "条件（？）" : "条件")
                    .font(.system(size: 11, weight: .black, design: .rounded))
            }
            .foregroundStyle(MegrumTheme.lavender)

            ForEach(Array(tile.tokens.prefix(3).enumerated()), id: \.offset) { _, token in
                Text(token)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(MegrumTheme.lavender.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
        }
        .accessibilityLabel("相手の希望条件 " + tile.tokens.joined(separator: "、"))
    }
}

/// 空セル（相手希望が取れない/候補なし）。
struct HomeDealEmptyCell: View {
    var side: CGFloat
    var label: String

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MegrumTheme.ink.opacity(0.05))
            .frame(width: side, height: side)
            .overlay {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(4)
            }
    }
}

/// 取引ブロック直下の達成カウンタ（例「3個以上：2/3 選択済み・あと1つで成立」）。
struct HomeDealAchievementBar: View {
    var achievement: HomeDealAchievement

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: achievement.satisfied ? "checkmark.seal.fill" : "circle.dashed")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(achievement.satisfied ? AnyShapeStyle(HomeDealGradient.selection) : AnyShapeStyle(MegrumTheme.muted))
            Text(achievement.text)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(achievement.satisfied ? MegrumTheme.ink : MegrumTheme.ink.opacity(0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (achievement.satisfied ? MegrumTheme.sky.opacity(0.14) : MegrumTheme.ink.opacity(0.04)),
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
    }
}

/// 選択済みチェックの水色→紫グラデ（notes/19 で唯一の意味色の一つ）。
enum HomeDealGradient {
    static let selection = LinearGradient(
        colors: [MegrumTheme.sky, MegrumTheme.lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// 選択肢ピル（選択肢1 / 選択肢2 / 定価 …）。常時表示で相手希望を切替。iter1226.374。
struct HomeWantedOptionPills: View {
    var options: [HomeIndividualListingWantedOption]
    var selectedID: UUID?
    var onSelect: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(labeledOptions.enumerated()), id: \.element.0.id) { _, entry in
                    let (option, label) = entry
                    pill(label: label, systemName: icon(for: option), selected: option.id == selectedID) {
                        onSelect(option.id)
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var labeledOptions: [(HomeIndividualListingWantedOption, String)] {
        var goodsIndex = 0
        return options.map { option in
            switch option.kind {
            case .cash:
                return (option, "定価")
            case .goods, .condition:
                goodsIndex += 1
                return (option, "選択肢\(goodsIndex)")
            }
        }
    }

    private func icon(for option: HomeIndividualListingWantedOption) -> String {
        switch option.kind {
        case .goods: "bookmark.fill"
        case .condition: "slider.horizontal.3"
        case .cash: "yensign"
        }
    }

    private func pill(label: String, systemName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .heavy))
                Text(label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(selected ? .white : MegrumTheme.lavender)
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background {
                if selected {
                    Capsule().fill(MegrumTheme.lavender)
                } else {
                    Capsule().fill(MegrumTheme.lavender.opacity(0.10))
                    Capsule().strokeBorder(MegrumTheme.lavender.opacity(0.28), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
