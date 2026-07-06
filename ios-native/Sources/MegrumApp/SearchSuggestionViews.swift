import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchSuggestionSectionsView: View {
    var sections: [SearchSuggestionSection]
    var selectedActions: Set<SearchSuggestionAction>
    var onSelect: (SearchSuggestionAction) -> Void
    var onWishSuggestionHorizontalDrag: () -> Void
    var showsWishEntry = false
    var showsListingEntry = false
    var onOpenWishPicker: () -> Void = {}
    var onOpenListingPicker: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 入口行：詳細な選択は専用画面へ（検索画面はシンプルに保つ）
            VStack(spacing: 10) {
                if showsWishEntry {
                    SearchEntryRow(
                        title: "ほしいものから探す",
                        systemImageName: "heart.fill",
                        tint: MegrumTheme.pink,
                        action: onOpenWishPicker
                    )
                }
                if showsListingEntry {
                    SearchEntryRow(
                        title: "個別募集から探す",
                        systemImageName: "bookmark.fill",
                        tint: MegrumTheme.lavender,
                        action: onOpenListingPicker
                    )
                }
            }

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: section.systemImageName)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(tint)

                Text(section.title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
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
            return item.subtitle == "グループ・作品"
        }
    }

    private var memberItems: [SearchSuggestionItem] {
        items.filter { item in
            if case .member = item.action {
                return true
            }
            return item.subtitle == "メンバー・キャラクター"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
