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
