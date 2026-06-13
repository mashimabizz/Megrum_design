import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsBulkTagRoute: Identifiable, Equatable {
    var itemIDs: Set<UUID>

    var id: String {
        itemIDs.map(\.uuidString).sorted().joined(separator: "-")
    }
}

struct GoodsQuickActionBackdrop: View {
    var onDismiss: () -> Void

    var body: some View {
        Color.black.opacity(0.12)
            .ignoresSafeArea()
            .onTapGesture(perform: onDismiss)
            .accessibilityLabel("メニューを閉じる")
    }
}

struct GoodsInventoryQuickActionPanel: View {
    var item: GoodsItem
    var onAction: (GoodsQuickActionKind) -> Void

    var body: some View {
        MegrumGlassGroup(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(GoodsTileCollectionCardStyle.hue(for: item))
                        .frame(width: 50, height: 64)
                        .overlay {
                            Text(GoodsTileCollectionCardStyle.glyph(for: item))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(MegrumTheme.ink)

                        Text("グッズ操作")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Spacer(minLength: 0)
                }

                ForEach(GoodsQuickActionKind.inventoryActions) { action in
                    Button(role: action.role) {
                        onAction(action)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: action.systemImage)
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 22)

                            Text(action.title)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))

                            Spacer()
                        }
                        .foregroundStyle(action.role == .destructive ? Color.red : MegrumTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .megrumLiquidGlass(
                            .rounded(cornerRadius: 17),
                            tint: (action.role == .destructive ? Color.red : MegrumTheme.lavender).opacity(0.12),
                            interactive: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(action.title)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.46), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 24, y: 14)
            .megrumLiquidGlass(.rounded(cornerRadius: 28), tint: Color.white.opacity(0.18))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

struct GoodsCollectionFloatingControls: View {
    var showsAddButton: Bool
    var addButtonLabel: String
    var addButtonHint: String
    var isSelectionMode: Bool
    var quickActionItem: GoodsItem?
    var selectedCount: Int
    var onAdd: () -> Void
    var onDismissQuickAction: () -> Void
    var onQuickAction: (GoodsQuickActionKind) -> Void
    var onBulkTag: () -> Void
    var onBulkDelete: () -> Void
    var onCancelSelection: () -> Void

    var body: some View {
        if showsAddButton && !isSelectionMode && quickActionItem == nil {
            AddGoodsButton(accessibilityLabel: addButtonLabel, accessibilityHint: addButtonHint, action: onAdd)
                .padding(.leading, FloatingActionLayoutMetrics.leadingPadding)
                .padding(.bottom, FloatingActionLayoutMetrics.bottomGapAboveFooter)
        }

        if let quickActionItem {
            GoodsQuickActionBackdrop(onDismiss: onDismissQuickAction)
            GoodsInventoryQuickActionPanel(
                item: quickActionItem,
                onAction: onQuickAction
            )
            .padding(.horizontal, GoodsSelectionFooterMetrics.horizontalPadding)
            .padding(.bottom, FloatingActionLayoutMetrics.contentBottomPadding)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        if isSelectionMode {
            GoodsSelectionFooter(
                selectedCount: selectedCount,
                onTag: onBulkTag,
                onDelete: onBulkDelete,
                onCancel: onCancelSelection
            )
            .padding(.horizontal, GoodsSelectionFooterMetrics.horizontalPadding)
            .padding(.bottom, GoodsSelectionFooterMetrics.bottomPadding)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct GoodsSelectionFooter: View {
    var selectedCount: Int
    var onTag: () -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        MegrumGlassGroup(spacing: GoodsSelectionFooterMetrics.actionSpacing) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Text("\(selectedCount)件を選択中")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Spacer()
                    Button("解除", action: onCancel)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                HStack(spacing: GoodsSelectionFooterMetrics.actionSpacing) {
                    GoodsSelectionFooterButton(title: "タグをつける", systemImage: "tag", role: nil, action: onTag)
                    GoodsSelectionFooterButton(title: "削除する", systemImage: "trash", role: .destructive, action: onDelete)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 20, y: 12)
            .megrumLiquidGlass(
                .rounded(cornerRadius: GoodsSelectionFooterMetrics.cornerRadius),
                tint: Color.white.opacity(0.16)
            )
        }
    }
}

private struct GoodsSelectionFooterButton: View {
    var title: String
    var systemImage: String
    var role: ButtonRole?
    var action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(role == .destructive ? Color.red : MegrumTheme.ink)
                .frame(maxWidth: .infinity, minHeight: GoodsSelectionFooterMetrics.actionHeight)
                .background(Color.white.opacity(0.18), in: Capsule())
                .megrumLiquidGlass(
                    .capsule,
                    tint: (role == .destructive ? Color.red : MegrumTheme.lavender).opacity(0.12),
                    interactive: true
                )
        }
        .buttonStyle(.plain)
    }
}

struct GoodsBulkTagSheet: View {
    var selectedCount: Int
    var onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tagDraft = ""

    private var trimmedTag: String {
        tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例：会場限定", text: $tagDraft)
                } header: {
                    Text("追加するタグ")
                } footer: {
                    Text("\(selectedCount)件のグッズに同じタグを追加します。")
                }
            }
            .navigationTitle("タグをつける")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        onApply(trimmedTag)
                        dismiss()
                    }
                    .disabled(trimmedTag.isEmpty)
                }
            }
        }
    }
}
