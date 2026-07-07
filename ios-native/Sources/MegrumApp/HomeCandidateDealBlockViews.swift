import Foundation
import MegrumDesign
import SwiftUI

/// 取引ブロック（うけとる ⇄ [相手希望 → マイグッズ]）。notes/19・iter1226.377。
/// 大枠なし。「ゆずる」は相手希望とマイグッズの中間上、「うけとる」と同じ段。
/// 指名は相手希望ごとに →候補スロット（タップでその画像に合う候補ポップアップ）。相手希望3件以上は折りたたむ。
struct HomeDealBlockView: View {
    var model: HomeDealBlockModel
    var onToggleReceive: (Int) -> Void
    var onToggleOffer: (Int) -> Void

    private let thumbSide: CGFloat = 58
    private let receiveCollapsedCount = 2
    private let partnerCollapsedCount = 2
    private let arrowWidth: CGFloat = 16
    private let tier1Height: CGFloat = 19
    private let tier2Height: CGFloat = 15
    @State private var showsReceiveList = false
    @State private var partnerExpanded = false
    @State private var offerPicker: HomeDealOfferPickerContext?

    // 二段目のコンテンツ（サムネ）が始まる位置に⇄矢印を合わせる（tier2ラベル＋spacing分下げる）。
    private var contentTopInset: CGFloat { tier2Height + 6 }

    private let receiveColumnWidth: CGFloat = 82

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 見出し（本文と分離して確実に揃える）
            VStack(spacing: 3) {
                // 一段目：うけとる ／ ゆずる（相手希望とマイグッズの中間上）
                HStack(spacing: 6) {
                    tierLabel("うけとる", qty: model.receive.qtyLabel, height: tier1Height)
                        .frame(width: receiveColumnWidth, alignment: .leading)
                    Color.clear.frame(width: arrowWidth)
                    tierLabel("ゆずる", qty: nil, height: tier1Height, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
                // 二段目：相手希望 ／ マイグッズ（うけとる列の下は空）
                HStack(spacing: 6) {
                    Color.clear.frame(width: receiveColumnWidth, height: tier2Height)
                    Color.clear.frame(width: arrowWidth)
                    HStack(spacing: 4) {
                        tierLabel("相手希望", qty: nil, height: tier2Height, alignment: .center, small: true)
                            .frame(maxWidth: .infinity)
                        Color.clear.frame(width: arrowWidth)
                        tierLabel("マイグッズ", qty: model.offer.qtyLabel, height: tier2Height, alignment: .center, small: true)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // 本文：うけとる列 ⇄ [相手希望 → マイグッズ]
            HStack(alignment: .top, spacing: 6) {
                receiveColumn
                    .frame(width: receiveColumnWidth, alignment: .leading)
                connectorArrow("arrow.left.arrow.right")
                giveRows
                    .frame(maxWidth: .infinity)
            }

            if let achievement = model.achievement {
                HomeDealAchievementBar(achievement: achievement)
            }
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
        .sheet(item: $offerPicker) { ctx in
            HomeOfferGoodsPickerSheet(
                requirementText: ctx.requirementText,
                cells: ctx.cells,
                onToggle: onToggleOffer
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - うけとる列

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
            onTap: model.receive.selectable ? { showsReceiveList = true } : nil
        )
    }

    // MARK: - 相手希望 → マイグッズ の行

    @ViewBuilder
    private var giveRows: some View {
        switch model.partner.kind {
        case .goods:
            namedRows
        case .condition:
            conditionRow
        case .cash:
            EmptyView()
        }
    }

    // 指名：相手希望画像ごとに →候補スロット。3件以上は折りたたみ。
    @ViewBuilder
    private var namedRows: some View {
        let pairings = Array(zip(model.partner.namedItems, offerRowsForNamed).enumerated())
        let collapse = pairings.count > partnerCollapsedCount + 1 && !partnerExpanded
        let visible = collapse ? Array(pairings.prefix(partnerCollapsedCount)) : pairings
        VStack(spacing: 8) {
            ForEach(visible, id: \.offset) { _, pair in
                pairRow(wish: pair.0, row: pair.1)
            }
            if collapse {
                HomeDealMoreButton(label: "他\(pairings.count - partnerCollapsedCount)件を見る") {
                    partnerExpanded = true
                }
            } else if pairings.count > partnerCollapsedCount + 1 {
                HomeDealMoreButton(label: "閉じる", systemName: "chevron.up") {
                    partnerExpanded = false
                }
            }
        }
    }

    /// namedItems と対応する offer 行（無ければ空行で穴埋め）。
    private var offerRowsForNamed: [HomeDealOfferRow] {
        let rows = model.offer.rows
        return model.partner.namedItems.indices.map { i in
            rows.indices.contains(i) ? rows[i] : HomeDealOfferRow(id: model.partner.namedItems[i].id, cells: [])
        }
    }

    private func pairRow(wish: HomeDealWishCell, row: HomeDealOfferRow) -> some View {
        HStack(alignment: .center, spacing: 4) {
            HomeDealWishThumb(item: wish, side: thumbSide)
                .frame(maxWidth: .infinity, alignment: .center)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(MegrumTheme.ink.opacity(0.3))
                .frame(width: arrowWidth)
            offerSlot(row: row, requirement: "「\(wish.title)」に合う候補")
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // 条件：アイコン → 候補スロット（数量ぶん）。ポップアップは合致する全候補。
    private var conditionRow: some View {
        HStack(alignment: .top, spacing: 4) {
            HomeDealConditionIcon(side: thumbSide, tentative: model.partner.conditionTile?.tentative ?? false)
                .frame(maxWidth: .infinity, alignment: .center)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(MegrumTheme.ink.opacity(0.3))
                .frame(width: arrowWidth)
                .padding(.top, (thumbSide - 12) / 2)
            conditionSlots
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var conditionSlots: some View {
        let cells = model.offer.flatCells
        let requirement = model.offer.qtyLabel
        VStack(spacing: 8) {
            if cells.isEmpty {
                HomeDealEmptyCell(side: thumbSide, label: "候補なし")
            } else {
                ForEach(cells.filter(\.selected)) { cell in
                    HomeDealThumb(cell: cell, side: thumbSide, onTap: { openPicker(cells: cells, requirement: requirement) })
                }
                if cells.filter(\.selected).count < model.offer.requiredCount {
                    HomeDealPickTile(side: thumbSide) { openPicker(cells: cells, requirement: requirement) }
                }
            }
        }
    }

    // 指名の1スロット：選択済みなら候補サムネ、無ければ「選ぶ」タイル。タップでその希望に合う候補ポップアップ。
    @ViewBuilder
    private func offerSlot(row: HomeDealOfferRow, requirement: String) -> some View {
        if row.cells.isEmpty {
            HomeDealEmptyCell(side: thumbSide, label: "候補なし")
        } else if let selected = row.cells.first(where: { $0.selected }) {
            HomeDealThumb(cell: selected, side: thumbSide, onTap: { openPicker(cells: row.cells, requirement: requirement) })
        } else {
            HomeDealPickTile(side: thumbSide) { openPicker(cells: row.cells, requirement: requirement) }
        }
    }

    private func openPicker(cells: [HomeDealGoodsCell], requirement: String?) {
        offerPicker = HomeDealOfferPickerContext(cells: cells, requirementText: requirement)
    }

    // MARK: - 見出し・矢印

    @ViewBuilder
    private func tierLabel(_ title: String, qty: String?, height: CGFloat, alignment: Alignment = .leading, small: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(title)
                .font(.system(size: small ? 11 : 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(small ? 0.6 : 0.82))
                .fixedSize()
            if let qty {
                Text("(\(qty))")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func connectorArrow(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(MegrumTheme.ink.opacity(0.3))
            .frame(width: arrowWidth, height: thumbSide)
            .accessibilityHidden(true)
    }
}

/// ゆずる候補ポップアップの提示コンテキスト（sheet(item:) 用）。iter1226.377。
struct HomeDealOfferPickerContext: Identifiable {
    let id = UUID()
    let cells: [HomeDealGoodsCell]
    let requirementText: String?
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

    // グッズ名は出さず画像のみ。チェック/?は枠からはみ出す位置に。iter1226.376。
    private var thumb: some View {
        ListingGoodsImage(url: cell.imageURL, title: cell.title, cornerRadius: 12)
            .frame(width: side, height: side)
            .overlay(alignment: .topLeading) {
                indicator.offset(x: -7, y: -7)
            }
            .overlay(alignment: .topTrailing) {
                if cell.tentative {
                    Text("?")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(MegrumTheme.conditionExact.opacity(0.95), in: Circle())
                        .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                        .offset(x: 7, y: -7)
                }
            }
    }

    @ViewBuilder
    private var indicator: some View {
        if cell.selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(HomeDealGradient.selection)
                .background(Circle().fill(.white).padding(2))
                .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
        } else if onTap != nil {
            ZStack {
                Circle()
                    .strokeBorder(
                        MegrumTheme.ink.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.6, dash: [3, 2.4])
                    )
                    .background(Circle().fill(.white.opacity(0.9)))
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.42))
            }
            .frame(width: 20, height: 20)
        }
    }
}

/// 相手のほしいもの画像（相手希望・指名）。選択なし表示専用。グッズ名は出さない。
struct HomeDealWishThumb: View {
    var item: HomeDealWishCell
    var side: CGFloat

    var body: some View {
        ListingGoodsImage(url: item.imageURL, title: item.title, cornerRadius: 12)
            .frame(width: side, height: side)
            .accessibilityLabel("相手のほしいもの \(item.title)")
    }
}

/// 条件指定の相手希望アイコン（スライダー＋不確定なら「?」）。条件文はブロック下の確認セクションへ。iter1226.376。
struct HomeDealConditionIcon: View {
    var side: CGFloat
    var tentative: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.10))
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.28), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if tentative {
                    Text("?")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(MegrumTheme.conditionExact.opacity(0.95), in: Circle())
                        .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                        .offset(x: 7, y: -7)
                }
            }
            .accessibilityLabel(tentative ? "条件（要確認）" : "条件")
    }
}

/// ゆずるの「選ぶ」タイル（タップで候補ポップアップを開く）。iter1226.376。
struct HomeDealPickTile: View {
    var side: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    MegrumTheme.lavender.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1.6, dash: [4, 3])
                )
                .background(MegrumTheme.lavender.opacity(0.06))
                .frame(width: side, height: side)
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .black))
                        Text("選ぶ")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("譲るグッズを選ぶ")
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

/// ゆずる候補ポップアップ。相手希望（条件/指名）に合致する手持ちを一覧で出して選ぶ。iter1226.376。
struct HomeOfferGoodsPickerSheet: View {
    var requirementText: String?
    var cells: [HomeDealGoodsCell]
    var onToggle: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedCount: Int { cells.filter(\.selected).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("譲るグッズを選ぶ")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Text("\(selectedCount)件選択中")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                if let requirementText {
                    Text("相手の希望：\(requirementText)")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
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
                .padding(.bottom, 20)
            }

            Button {
                dismiss()
            } label: {
                Text("決定")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.canvas)
    }

    private func row(_ cell: HomeDealGoodsCell) -> some View {
        Button {
            onToggle(cell.index)
        } label: {
            HStack(spacing: 12) {
                ListingGoodsImage(url: cell.imageURL, title: cell.title, cornerRadius: 10)
                    .frame(width: 52, height: 52)
                Text(cell.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: cell.selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(cell.selected ? AnyShapeStyle(HomeDealGradient.selection) : AnyShapeStyle(MegrumTheme.ink.opacity(0.24)))
            }
            .padding(10)
            .background(
                (cell.selected ? MegrumTheme.lavender.opacity(0.10) : MegrumTheme.ink.opacity(0.035)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cell.title)
        .accessibilityAddTraits(cell.selected ? [.isSelected] : [])
    }
}

/// 条件パターンの「条件のグッズを確認！」セクション。notes/19 Phase4・iter1226.375/376。
/// 条件文＋①参考画像2枚 or ②「グループ メンバー 種別 #シリーズ」でGoogle画像検索ボタン。
struct HomeConditionSeriesCheckSection: View {
    var model: HomeConditionSeriesCheckModel
    @State private var browserLink: MegrumBrowserLink?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !model.conditionText.isEmpty {
                (Text("条件：").foregroundStyle(MegrumTheme.muted) + Text(model.conditionText).foregroundStyle(MegrumTheme.ink))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 7) {
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .bold))
                Text("条件のグッズを確認！")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
            }
            .foregroundStyle(MegrumTheme.ink)

            if model.usesReferenceImages {
                HStack(spacing: 10) {
                    ForEach(Array(model.referenceImageURLs.prefix(2).enumerated()), id: \.offset) { _, url in
                        VStack(spacing: 4) {
                            ListingGoodsImage(url: url, title: "参考", cornerRadius: 12)
                                .frame(width: 92, height: 92)
                            Text("参考画像")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer(minLength: 0)
                }
            } else if let searchURL = model.searchURL {
                Button {
                    browserLink = MegrumBrowserLink(url: searchURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .black))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("画像で検索して確認")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                            Text(model.searchQuery)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity)
                    .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MegrumTheme.lavender.opacity(0.22), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("画像で検索して確認、\(model.searchQuery)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(MegrumTheme.sky.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .sheet(item: $browserLink) { link in
            #if os(iOS)
            MegrumSafariView(url: link.url)
                .ignoresSafeArea()
            #endif
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
