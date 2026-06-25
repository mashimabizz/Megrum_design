import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchFilterSummaryBar: View {
    var activeFilterCount: Int
    var summaryTitles: [String]
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)

                    Text("絞り込み")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Spacer()

                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)件")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(MegrumTheme.lavender, in: Capsule())
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(MegrumTheme.muted)
                }

                if summaryTitles.isEmpty {
                    Text("グループを選ぶと、メンバーとグッズタグを選択できます")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(summaryTitles, id: \.self) { title in
                                Text(title)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(.white.opacity(0.76), in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SearchContent: View {
    var activeFilterCount: Int
    var activeCriteriaChips: [SearchActiveCriteriaChipItem]
    var hasSearchCriteria: Bool
    var resultCount: Int
    var isSearching: Bool
    var isSearchResultsEmpty: Bool
    var results: [SearchResultItem]
    var suggestionSections: [SearchSuggestionSection]
    var selectedSuggestionActions: Set<SearchSuggestionAction>
    @Binding var sort: SearchResultSort
    var appState: MegrumAppState?
    var viewerID: UUID?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onBack: () -> Void
    var onRemoveActiveCriteria: (SearchActiveCriteriaRemoval) -> Void
    var onFilterTap: () -> Void
    var onSelectSuggestion: (SearchSuggestionAction) -> Void
    var onWishSuggestionHorizontalDrag: () -> Void
    var onStartProposal: (GoodsItem) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onReportItem: (GoodsItem, GoodsReportReason, String) -> Void

    private var hasFilteredResults: Bool {
        !results.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SearchResultsHeader(
                    chips: hasSearchCriteria ? activeCriteriaChips : [],
                    onBack: onBack,
                    onRemove: onRemoveActiveCriteria
                )

                if hasSearchCriteria {
                    SearchResultToolbar(
                        resultCount: resultCount,
                        isSearching: isSearching,
                        sort: $sort
                    )

                    if isSearching && isSearchResultsEmpty {
                        SearchResultSkeleton()
                    } else if !hasFilteredResults {
                        SearchEmptyMessage()
                    } else {
                        SearchResultGrid(
                            results: results,
                            appState: appState,
                            viewerID: viewerID,
                            onStartProposal: onStartProposal,
                            onOpenOwnerProfile: onOpenOwnerProfile,
                            onReportItem: onReportItem
                        )
                        AdBannerSlot(
                            placement: .searchResultsBanner,
                            displayContext: adDisplayContext
                        )
                    }
                } else {
                    SearchSuggestionSectionsView(
                        sections: suggestionSections,
                        selectedActions: selectedSuggestionActions,
                        onSelect: onSelectSuggestion,
                        onWishSuggestionHorizontalDrag: onWishSuggestionHorizontalDrag
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 132)
        }
    }
}

private struct SearchResultsHeader: View {
    var chips: [SearchActiveCriteriaChipItem]
    var onBack: () -> Void
    var onRemove: (SearchActiveCriteriaRemoval) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.86), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            if chips.isEmpty {
                Spacer()
            } else {
                SearchActiveCriteriaChips(
                    chips: chips,
                    onRemove: onRemove
                )
            }
        }
    }
}
