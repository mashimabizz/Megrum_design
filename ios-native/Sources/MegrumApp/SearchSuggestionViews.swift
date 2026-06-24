import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchSuggestionSectionsView: View {
    var sections: [SearchSuggestionSection]
    var selectedActions: Set<SearchSuggestionAction>
    var onSelect: (SearchSuggestionAction) -> Void
    var onWishSuggestionHorizontalDrag: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach(sections) { section in
                SearchSuggestionSectionView(
                    section: section,
                    selectedActions: selectedActions,
                    onSelect: onSelect,
                    onWishSuggestionHorizontalDrag: onWishSuggestionHorizontalDrag
                )
            }
        }
    }
}

private struct SearchSuggestionSectionView: View {
    var section: SearchSuggestionSection
    var selectedActions: Set<SearchSuggestionAction>
    var onSelect: (SearchSuggestionAction) -> Void
    var onWishSuggestionHorizontalDrag: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: section.systemImageName)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(tint)

                Text(section.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()
            }

            switch section.id {
            case "oshi":
                SearchOshiSuggestionRows(
                    items: section.items,
                    selectedActions: selectedActions,
                    tint: tint,
                    onSelect: onSelect
                )
            case "wish":
                SearchWishSuggestionImageRow(
                    items: section.items,
                    selectedActions: selectedActions,
                    tint: tint,
                    onSelect: onSelect,
                    onHorizontalDrag: onWishSuggestionHorizontalDrag
                )
            default:
                SearchSuggestionTagWrap(
                    items: section.items,
                    selectedActions: selectedActions,
                    tint: tint,
                    onSelect: onSelect
                )
            }
        }
    }

    private var tint: Color {
        switch section.tintRole {
        case .lavender:
            MegrumTheme.lavender
        case .pink:
            MegrumTheme.pink
        case .muted:
            MegrumTheme.muted
        }
    }
}

private struct SearchOshiSuggestionRows: View {
    var items: [SearchSuggestionItem]
    var selectedActions: Set<SearchSuggestionAction>
    var tint: Color
    var onSelect: (SearchSuggestionAction) -> Void

    private var groupItems: [SearchSuggestionItem] {
        items.filter { item in
            if case .group = item.action {
                return true
            }
            return item.subtitle == "L1"
        }
    }

    private var memberItems: [SearchSuggestionItem] {
        items.filter { item in
            if case .member = item.action {
                return true
            }
            return item.subtitle == "L2"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchSuggestionTagWrap(
                items: groupItems,
                selectedActions: selectedActions,
                tint: tint,
                onSelect: onSelect
            )

            if !memberItems.isEmpty {
                SearchSuggestionTagWrap(
                    items: memberItems,
                    selectedActions: selectedActions,
                    tint: tint,
                    onSelect: onSelect
                )
            }
        }
    }
}

private struct SearchSuggestionTagWrap: View {
    var items: [SearchSuggestionItem]
    var selectedActions: Set<SearchSuggestionAction>
    var tint: Color
    var onSelect: (SearchSuggestionAction) -> Void

    var body: some View {
        WrappingTagFlow(spacing: 8, rowSpacing: 9) {
            ForEach(items) { item in
                SearchSuggestionTagButton(
                    title: item.title,
                    tint: tint,
                    isSelected: selectedActions.contains(item.action),
                    action: {
                        onSelect(item.action)
                    }
                )
            }
        }
    }
}

private struct SearchSuggestionTagButton: View {
    var title: String
    var tint: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14.5, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                .background(isSelected ? tint : Color.white.opacity(0.90), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? tint.opacity(0.68) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("検索条件に追加します")
    }
}

private struct SearchWishSuggestionImageRow: View {
    var items: [SearchSuggestionItem]
    var selectedActions: Set<SearchSuggestionAction>
    var tint: Color
    var onSelect: (SearchSuggestionAction) -> Void
    var onHorizontalDrag: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    SearchSuggestionImageChip(
                        item: item,
                        tint: tint,
                        isSelected: selectedActions.contains(item.action),
                        action: {
                            onSelect(item.action)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .simultaneousGesture(horizontalScrollSuppressionGesture, including: .gesture)
    }

    private var horizontalScrollSuppressionGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard SearchBackSwipeResolver.isNestedHorizontalScroll(translation: value.translation) else {
                    return
                }
                onHorizontalDrag()
            }
            .onEnded { value in
                guard SearchBackSwipeResolver.isNestedHorizontalScroll(translation: value.translation) else {
                    return
                }
                onHorizontalDrag()
            }
    }
}

private struct SearchSuggestionImageChip: View {
    var item: SearchSuggestionItem
    var tint: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                SearchSuggestionArtwork(
                    imageURL: item.imageURL,
                    systemImageName: item.systemImageName,
                    title: item.title,
                    tint: tint
                )
                .frame(width: 82, height: 82)

                Text(item.title)
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .frame(width: 88)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(MegrumTheme.lavender, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint("検索条件に追加します")
    }
}

private struct SearchSuggestionArtwork: View {
    var imageURL: URL?
    var systemImageName: String?
    var title: String
    var tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(tint.opacity(0.16))
            .overlay {
                if let imageURL {
                    GoodsRemoteImage(url: imageURL, cornerRadius: 22, placeholderIconSize: 24)
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: systemImageName ?? "sparkles")
                            .font(.system(size: 26, weight: .heavy))
                        Text(String(title.prefix(1)))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(tint)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
    }
}
