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
    /// 折りたたみ表示の上限（これを超えたら「+N」タイル／「他N件を見る」に畳む）。notes/19 の多数（4枚超）対策。
    private let receiveCollapsedCount = 2
    private let offerCollapsedCount = 3
    @State private var offerExpanded = false
    @State private var showsReceiveList = false

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
        .sheet(isPresented: $showsReceiveList) {
            HomeReceiveGoodsListSheet(
                cells: model.receive.cells,
                selectable: model.receive.selectable,
                onToggle: onToggleReceive
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 受け取る（多数はサムネ2枚＋「+N」→一覧ポップアップ）

    @ViewBuilder
    private var receiveColumn: some View {
        let cells = model.receive.cells
        VStack(alignment: .leading, spacing: 8) {
            if cells.count > receiveCollapsedCount + 1 {
                ForEach(cells.prefix(receiveCollapsedCount)) { cell in
                    receiveThumb(cell)
                }
                HomeDealCountTile(side: thumbSide, label: "+\(cells.count - receiveCollapsedCount)", caption: "すべて見る") {
                    showsReceiveList = true
                }
            } else {
                ForEach(cells) { cell in
                    receiveThumb(cell)
                }
            }
        }
    }

    private func receiveThumb(_ cell: HomeDealGoodsCell) -> some View {
        HomeDealThumb(
            cell: cell,
            side: thumbSide,
            onTap: model.receive.selectable ? { onToggleReceive(cell.index) } : nil
        )
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
            offerFlatColumn
        }
    }

    /// 条件パターンのゆずる列。多数（4枚超）は未選択優先で3件＋「他N件を見る」で縦に展開。
    @ViewBuilder
    private var offerFlatColumn: some View {
        let cells = orderedOfferCells
        VStack(alignment: .leading, spacing: 8) {
            if cells.isEmpty {
                HomeDealEmptyCell(side: thumbSide, label: "候補なし")
            } else if cells.count > offerCollapsedCount + 1, !offerExpanded {
                ForEach(cells.prefix(offerCollapsedCount)) { cell in
                    HomeDealThumb(cell: cell, side: thumbSide, onTap: { onToggleOffer(cell.index) })
                }
                HomeDealMoreButton(label: "他\(cells.count - offerCollapsedCount)件を見る") {
                    offerExpanded = true
                }
            } else {
                ForEach(cells) { cell in
                    HomeDealThumb(cell: cell, side: thumbSide, onTap: { onToggleOffer(cell.index) })
                }
                if cells.count > offerCollapsedCount + 1 {
                    HomeDealMoreButton(label: "閉じる", systemName: "chevron.up") {
                        offerExpanded = false
                    }
                }
            }
        }
    }

    /// 未選択優先の並び（選ぶべき候補を上に）。index は保持したまま。
    private var orderedOfferCells: [HomeDealGoodsCell] {
        let cells = model.offer.rows.first?.cells ?? []
        return cells.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.selected != rhs.element.selected {
                    return !lhs.element.selected && rhs.element.selected
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
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

/// 「+N」タイル（受け取るが多数のとき、サムネの後ろに置いて一覧ポップアップを開く）。
struct HomeDealCountTile: View {
    var side: CGFloat
    var label: String
    var caption: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(width: side, height: side)
                    .overlay {
                        Text(label)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(MegrumTheme.lavender.opacity(0.28), lineWidth: 1)
                    }
                Text(caption)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .lineLimit(1)
                    .frame(width: side)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)、\(caption)")
    }
}

/// 「他N件を見る／閉じる」列内トグルボタン。
struct HomeDealMoreButton: View {
    var label: String
    var systemName: String = "chevron.down"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                Image(systemName: systemName)
                    .font(.system(size: 9, weight: .black))
            }
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// 受け取るグッズの一覧ポップアップ（画像＋グッズ名で全件）。多数時に「+N」から開く。notes/19。
struct HomeReceiveGoodsListSheet: View {
    var cells: [HomeDealGoodsCell]
    var selectable: Bool
    var onToggle: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("受け取るもの")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text("\(cells.count)件")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(cells) { cell in
                        row(cell)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.canvas)
    }

    @ViewBuilder
    private func row(_ cell: HomeDealGoodsCell) -> some View {
        let content = HStack(spacing: 12) {
            ListingGoodsImage(url: cell.imageURL, title: cell.title, cornerRadius: 10)
                .frame(width: 52, height: 52)
            Text(cell.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            if selectable {
                Image(systemName: cell.selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(cell.selected ? AnyShapeStyle(HomeDealGradient.selection) : AnyShapeStyle(MegrumTheme.ink.opacity(0.24)))
            }
        }
        .padding(10)
        .background(MegrumTheme.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        if selectable {
            Button { onToggle(cell.index) } label: { content }
                .buttonStyle(.plain)
        } else {
            content
        }
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
