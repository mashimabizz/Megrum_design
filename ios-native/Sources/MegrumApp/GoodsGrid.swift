import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsGrid: View {
    var items: [GoodsItem]
    var columns: Int = 3
    @State private var detailItem: GoodsItem?
    @State private var actionMessage: String?

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 16) {
            ForEach(items) { item in
                GoodsTile(
                    item: item,
                    onOpenDetail: {
                        detailItem = item
                    },
                    onAction: { action in
                        handle(action, item: item)
                    }
                )
            }
        }
        .sheet(item: $detailItem) { item in
            NavigationStack {
                GoodsDetailSheet(item: item)
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
    }

    private func handle(_ action: GoodsTileAction, item: GoodsItem) {
        switch action {
        case .detail:
            detailItem = item
        case .addToExchangeList:
            actionMessage = "「\(item.title)」を交換リストに追加する処理は、打診フローのSwift化で接続します。"
        case .hide:
            actionMessage = "「\(item.title)」を非表示にする処理は、在庫編集のSwift化で接続します。"
        case .report:
            actionMessage = "「\(item.title)」の通報導線は、通報フローのSwift化で接続します。"
        case .delete:
            actionMessage = "「\(item.title)」を削除する処理は、在庫削除APIのSwift化で接続します。"
        }
    }
}

struct GoodsTile: View {
    var item: GoodsItem
    var onOpenDetail: () -> Void
    var onAction: (GoodsTileAction) -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tileGradient)
                    .aspectRatio(0.78, contentMode: .fit)
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
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 5)

                Text(item.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(GoodsTileAction.visibleActions) { action in
                Button(role: action.role) {
                    onAction(action)
                } label: {
                    Label(action.title, systemImage: action.symbolName)
                }
            }
        }
        .accessibilityElement(children: .combine)
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
    case hide
    case report
    case delete

    static var visibleActions: [GoodsTileAction] {
        [.detail, .addToExchangeList, .hide, .report, .delete]
    }

    var id: String { title }

    var title: String {
        switch self {
        case .detail:
            "詳細を見る"
        case .addToExchangeList:
            "交換リストに追加"
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
        case .detail, .addToExchangeList, .hide, .report:
            nil
        }
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
