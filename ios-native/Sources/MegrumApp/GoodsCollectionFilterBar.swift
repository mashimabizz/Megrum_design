import MegrumCore
import MegrumDesign
import SwiftUI

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
