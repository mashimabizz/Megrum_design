import MegrumCore
import MegrumDesign
import SwiftUI

struct CollectionHeader: View {
    var title: String
    var subtitle: String
    @Binding var columns: Int
    var accessory: AnyView?
    var showsColumnToggle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 16) {
                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                if showsColumnToggle {
                    ColumnToggleButton(columns: $columns)
                        .padding(.top, 3)
                }
            }

            if let accessory {
                accessory
                    .padding(.top, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
                    .padding(.bottom, CollectionScreenLayoutMetrics.headerAccessoryVerticalPadding)
            }

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ColumnToggleButton: View {
    @Binding var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        Button {
            columns = layout.nextColumns
        } label: {
            HStack(spacing: 8) {
                GridColumnGlyph(columns: layout.columns)

                Text("\(layout.columns)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MegrumTheme.ink)
            }
            .frame(width: 64, height: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("表示列数を変更")
        .accessibilityValue("\(layout.columns)列")
        .accessibilityHint("タップすると\(layout.nextColumns)列に切り替えます")
    }
}

private struct GridColumnGlyph: View {
    var columns: Int

    private var layout: GoodsGridLayout {
        GoodsGridLayout(columns: columns)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<GoodsGridLayout.maximumColumns, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index < layout.columns ? MegrumTheme.ink : MegrumTheme.ink.opacity(0.18))
                    .frame(width: 4, height: index < layout.columns ? 18 : 12)
            }
        }
        .accessibilityHidden(true)
    }
}

struct AddGoodsButton: View {
    var accessibilityLabel: String
    var accessibilityHint: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

struct InventoryStatusTabs: View {
    @Binding var selectedStatus: GoodsEntryStatus
    var counts: [GoodsEntryStatus: Int]

    private let statuses: [GoodsEntryStatus] = [.active, .keep, .traded]

    var body: some View {
        Picker("マイグッズの表示", selection: $selectedStatus) {
            ForEach(statuses) { status in
                Text("\(status.inventoryTabTitle) \(counts[status, default: 0])")
                    .tag(status)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("マイグッズの表示切り替え")
    }
}

struct CollectionLoadingNotice: View {
    var body: some View {
        Label("グッズを読み込み中", systemImage: "arrow.clockwise")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("グッズを読み込み中")
    }
}

struct CollectionFilterBar: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedGroupID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    @Binding var selectedTagNames: Set<String>
    var items: [GoodsItem]
    var availableTagNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: CollectionScreenLayoutMetrics.filterBarSpacing) {
            FilterChoiceRow(title: "グループ", isLoading: appState.isLoadingOshiGroups) {
                ChoiceChip(title: "すべて", isSelected: selectedGroupID == nil, style: .compact) {
                    selectedGroupID = nil
                }
                ForEach(availableGroups) { group in
                    ChoiceChip(title: group.name, isSelected: selectedGroupID == group.id, style: .compact) {
                        selectedGroupID = group.id
                    }
                }
            }

            FilterChoiceRow(title: "グッズ種別", isLoading: appState.isLoadingGoodsTypes) {
                ChoiceChip(title: "すべて", isSelected: selectedGoodsTypeID == nil, style: .compact) {
                    selectedGoodsTypeID = nil
                }
                ForEach(availableGoodsTypes) { goodsType in
                    ChoiceChip(title: goodsType.name, isSelected: selectedGoodsTypeID == goodsType.id, style: .compact) {
                        selectedGoodsTypeID = goodsType.id
                    }
                }
            }

            if !availableTagNames.isEmpty || !selectedTagNames.isEmpty {
                FilterChoiceRow(title: "タグ", isLoading: false) {
                    ChoiceChip(title: "すべて", isSelected: selectedTagNames.isEmpty, style: .compact) {
                        selectedTagNames = []
                    }
                    ForEach(availableTagNames, id: \.self) { tagName in
                        ChoiceChip(title: "#\(tagName)", isSelected: selectedTagNames.contains(tagName), style: .compact) {
                            if selectedTagNames.contains(tagName) {
                                selectedTagNames.remove(tagName)
                            } else {
                                selectedTagNames.insert(tagName)
                            }
                        }
                    }
                }
            }
        }
    }

    private var availableGroups: [OshiGroup] {
        GoodsCollectionFilterChoices.groups(
            items: items,
            allGroups: appState.oshiGroups
        )
    }

    private var availableGoodsTypes: [GoodsType] {
        GoodsCollectionFilterChoices.goodsTypes(
            items: items,
            allGoodsTypes: appState.goodsTypes
        )
    }
}

private struct FilterChoiceRow<Content: View>: View {
    var title: String
    var isLoading: Bool
    var content: Content

    init(title: String, isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isLoading = isLoading
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(width: CollectionScreenLayoutMetrics.filterRowLabelWidth, height: CollectionScreenLayoutMetrics.filterChipHeight, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CollectionScreenLayoutMetrics.filterRowChipSpacing) {
                    content
                }
            }
        }
    }
}

enum ChoiceChipStyle {
    case regular
    case compact
}

struct ChoiceChip: View {
    var title: String
    var isSelected: Bool
    var style: ChoiceChipStyle = .regular
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        baseLabel
    }

    private var baseLabel: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(backgroundStyle, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(isSelected ? 0.7 : 0.45), lineWidth: 1)
            }
    }

    private var backgroundStyle: some ShapeStyle {
        isSelected
            ? AnyShapeStyle(MegrumTheme.lavender)
            : AnyShapeStyle(.regularMaterial)
    }

    private var fontSize: CGFloat {
        switch style {
        case .regular:
            15
        case .compact:
            CollectionScreenLayoutMetrics.filterChipFontSize
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .regular:
            16
        case .compact:
            CollectionScreenLayoutMetrics.filterChipHorizontalPadding
        }
    }

    private var height: CGFloat {
        switch style {
        case .regular:
            42
        case .compact:
            CollectionScreenLayoutMetrics.filterChipHeight
        }
    }
}
