import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsGridLayout: Equatable {
    static let minimumColumns = 3
    static let maximumColumns = 5
    static let columnSpacing: CGFloat = 14
    static let rowSpacing: CGFloat = 16
    static let tileAspectRatio: CGFloat = 0.78
    static let tileCornerRadius: CGFloat = 18

    var requestedColumns: Int

    init(columns: Int = Self.minimumColumns) {
        self.requestedColumns = columns
    }

    var columns: Int {
        min(Self.maximumColumns, max(Self.minimumColumns, requestedColumns))
    }

    var nextColumns: Int {
        columns >= Self.maximumColumns ? Self.minimumColumns : columns + 1
    }

    var skeletonTileCount: Int {
        columns * 2
    }
}

struct GoodsGrid: View {
    var items: [GoodsItem]
    var columns: Int = 3
    var viewerID: UUID?
    var onOpenOwnerProfile: ((UUID) -> Void)?
    var onAddToExchangeList: ((GoodsItem) -> Void)?
    var onCreateIndividualListing: ((GoodsItem) -> Void)?
    var onEditItem: ((GoodsItem) -> Void)?
    var onHideItem: ((GoodsItem) -> Void)?
    var onDeleteItem: ((GoodsItem) -> Void)?
    var onReportItem: ((GoodsItem, GoodsReportReason, String) -> Void)?
    var busyItemID: UUID?
    @State private var detailItem: GoodsItem?
    @State private var actionMessage: String?
    @State private var pendingDeleteItem: GoodsItem?
    @State private var reportItem: GoodsItem?

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: GoodsGridLayout.columnSpacing), count: layout.columns)
    }

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: GoodsGridLayout.rowSpacing) {
            ForEach(items) { item in
                GoodsTile(
                    item: item,
                    actions: actions(for: item),
                    onOpenDetail: {
                        if let onOpenOwnerProfile, item.ownerID != viewerID {
                            onOpenOwnerProfile(item.ownerID)
                        } else {
                            detailItem = item
                        }
                    },
                    onAction: { action in
                        handle(action, item: item)
                    },
                    isBusy: busyItemID == item.id
                )
            }
        }
        .sheet(item: $detailItem) { item in
            NavigationStack {
                GoodsDetailSheet(item: item)
            }
        }
        .sheet(item: $reportItem) { item in
            NavigationStack {
                GoodsReportSheet(item: item) { reason, note in
                    onReportItem?(item, reason, note)
                    reportItem = nil
                }
            }
        }
        .alert("まだ接続していません", isPresented: Binding(
            get: { actionMessage != nil },
            set: { if !$0 { actionMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let actionMessage {
                Text(actionMessage)
            }
        }
        .confirmationDialog("削除しますか？", isPresented: Binding(
            get: { pendingDeleteItem != nil },
            set: { if !$0 { pendingDeleteItem = nil } }
        ), titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                if let pendingDeleteItem {
                    onDeleteItem?(pendingDeleteItem)
                }
                pendingDeleteItem = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteItem = nil
            }
        } message: {
            if let pendingDeleteItem {
                Text("「\(pendingDeleteItem.title)」を削除します。")
            }
        }
    }

    private func handle(_ action: GoodsTileAction, item: GoodsItem) {
        switch action {
        case .detail:
            detailItem = item
        case .addToExchangeList:
            if let onAddToExchangeList {
                onAddToExchangeList(item)
            } else {
                actionMessage = "「\(item.title)」を交換リストに追加する処理は、打診フローのSwift化で接続します。"
            }
        case .createIndividualListing:
            if let onCreateIndividualListing {
                onCreateIndividualListing(item)
            } else {
                actionMessage = "「\(item.title)」から個別募集を作成する処理は、Wish画面で使えます。"
            }
        case .edit:
            if item.ownerID == viewerID, let onEditItem {
                onEditItem(item)
            } else {
                actionMessage = "「\(item.title)」の編集は、自分の在庫/Wishでのみ使えます。"
            }
        case .hide:
            if item.ownerID == viewerID, let onHideItem {
                onHideItem(item)
            } else {
                actionMessage = "「\(item.title)」を非表示にする処理は、自分の在庫/Wishでのみ使えます。"
            }
        case .report:
            if item.ownerID != viewerID, onReportItem != nil {
                reportItem = item
            } else {
                actionMessage = "「\(item.title)」の通報導線は、他のユーザーのグッズでのみ使えます。"
            }
        case .delete:
            if item.ownerID == viewerID, onDeleteItem != nil {
                pendingDeleteItem = item
            } else {
                actionMessage = "「\(item.title)」を削除する処理は、自分の在庫/Wishでのみ使えます。"
            }
        }
    }

    private func actions(for item: GoodsItem) -> [GoodsTileAction] {
        guard let viewerID else {
            return [.detail]
        }
        if item.ownerID == viewerID {
            var actions: [GoodsTileAction] = [.detail]
            if onEditItem != nil {
                actions.append(.edit)
            }
            if onCreateIndividualListing != nil {
                actions.append(.createIndividualListing)
            }
            if onHideItem != nil {
                actions.append(.hide)
            }
            if onDeleteItem != nil {
                actions.append(.delete)
            }
            return actions
        }
        var actions: [GoodsTileAction] = [.detail]
        if onAddToExchangeList != nil {
            actions.append(.addToExchangeList)
        }
        if onReportItem != nil {
            actions.append(.report)
        }
        return actions
    }
}

struct GoodsTile: View {
    var item: GoodsItem
    var actions: [GoodsTileAction] = GoodsTileAction.visibleActions
    var onOpenDetail: () -> Void
    var onAction: (GoodsTileAction) -> Void
    var isBusy = false

    var body: some View {
        Button(action: onOpenDetail) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                    .fill(tileGradient)
                    .aspectRatio(GoodsGridLayout.tileAspectRatio, contentMode: .fit)
                    .overlay {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous))
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.74))
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if let tag = item.tags.first {
                            GoodsTagPill(name: tag.name, fontSize: 11, horizontalPadding: 9)
                                .padding(8)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if item.quantity > 1 {
                            GoodsQuantityBadge(quantity: item.quantity)
                                .padding(8)
                        }
                    }
                    .overlay {
                        if isBusy {
                            RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                                .fill(.black.opacity(0.18))
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 5)

                Text(item.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .contextMenu {
            ForEach(primaryActions) { action in
                Button(role: action.role) {
                    onAction(action)
                } label: {
                    Label(action.title, systemImage: action.symbolName)
                }
            }
            if !destructiveActions.isEmpty {
                Divider()
                ForEach(destructiveActions) { action in
                    Button(role: action.role) {
                        onAction(action)
                    } label: {
                        Label(action.title, systemImage: action.symbolName)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint(Text(accessibilityHint))
    }

    private var primaryActions: [GoodsTileAction] {
        actions.filter { !$0.isDestructive }
    }

    private var destructiveActions: [GoodsTileAction] {
        actions.filter(\.isDestructive)
    }

    private var accessibilityValue: String {
        var values = ["\(item.quantity)点"]
        if let tag = item.tags.first {
            values.append("#\(tag.name)")
        }
        if isBusy {
            values.append("処理中")
        }
        return values.joined(separator: "、")
    }

    private var accessibilityHint: String {
        if isBusy {
            return "処理が終わるまで操作できません。"
        }
        if actions.count > 1 {
            return "ダブルタップで詳細を開きます。長押しで操作メニューを開けます。"
        }
        return "ダブルタップで詳細を開きます。"
    }

    private var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                MegrumTheme.sky.opacity(0.62),
                MegrumTheme.lavender.opacity(0.72),
                MegrumTheme.pink.opacity(0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum GoodsTileAction: CaseIterable, Identifiable {
    case detail
    case addToExchangeList
    case createIndividualListing
    case edit
    case hide
    case report
    case delete

    static var visibleActions: [GoodsTileAction] {
        [.detail, .addToExchangeList, .edit, .hide, .report, .delete]
    }

    var id: String { title }

    var title: String {
        switch self {
        case .detail:
            "詳細を見る"
        case .addToExchangeList:
            "交換リストに追加"
        case .createIndividualListing:
            "これで個別募集する"
        case .edit:
            "編集"
        case .hide:
            "非表示にする"
        case .report:
            "通報する"
        case .delete:
            "削除する"
        }
    }

    var symbolName: String {
        switch self {
        case .detail:
            "info.circle"
        case .addToExchangeList:
            "plus.circle"
        case .createIndividualListing:
            "rectangle.stack.badge.plus"
        case .edit:
            "square.and.pencil"
        case .hide:
            "eye.slash"
        case .report:
            "exclamationmark.bubble"
        case .delete:
            "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .detail, .addToExchangeList, .createIndividualListing, .edit, .hide, .report:
            nil
        }
    }

    var isDestructive: Bool {
        role == .destructive
    }
}

private struct GoodsDetailSheet: View {
    var item: GoodsItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                copy
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("グッズ詳細")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }

    private var hero: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        MegrumTheme.sky.opacity(0.6),
                        MegrumTheme.lavender.opacity(0.72),
                        MegrumTheme.pink.opacity(0.58)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(0.78, contentMode: .fit)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .overlay(alignment: .topTrailing) {
                if let tag = item.tags.first {
                    GoodsTagPill(name: tag.name, fontSize: 13, horizontalPadding: 12)
                        .padding(14)
                }
            }
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 22, y: 12)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if !item.tags.isEmpty {
                FlowTags(tags: item.tags)
            }

            HStack(spacing: 12) {
                DetailMetric(label: "数量", value: "\(item.quantity)")
                DetailMetric(label: "状態", value: "交換候補")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GoodsReportSheet: View {
    var item: GoodsItem
    var onSubmit: (GoodsReportReason, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: GoodsReportReason = .fakeItem
    @State private var note = ""

    var body: some View {
        Form {
            Section("対象") {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Section("理由") {
                Picker("理由", selection: $reason) {
                    ForEach(GoodsReportReason.allCases) { reason in
                        Text(reason.displayName).tag(reason)
                    }
                }
            }

            Section("補足") {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("通報")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("送信") {
                    onSubmit(reason, note)
                    dismiss()
                }
            }
        }
    }
}

private struct GoodsTagPill: View {
    var name: String
    var fontSize: CGFloat
    var horizontalPadding: CGFloat

    var body: some View {
        Text("# \(name)")
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 7)
            .background(.white.opacity(0.86), in: Capsule())
    }
}

private struct GoodsQuantityBadge: View {
    var quantity: Int

    var body: some View {
        Text("×\(quantity)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(MegrumTheme.lavender, in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
            .accessibilityHidden(true)
    }
}

private struct FlowTags: View {
    var tags: [GoodsTag]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags) { tag in
                GoodsTagPill(name: tag.name, fontSize: 12, horizontalPadding: 11)
            }
        }
    }
}

private struct DetailMetric: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
