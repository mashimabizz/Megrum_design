import MegrumCore
import MegrumDesign
import SwiftUI

private struct SearchInputBar: View {
    @Binding var query: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink)

            TextField("さがす...", text: $query)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .disableAutocorrection(true)
                .submitLabel(.search)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .megrumLiquidGlass(.capsule, tint: MegrumTheme.sky.opacity(0.10), interactive: true)
    }
}

struct SearchFooterBar: View {
    @Binding var query: String
    var activeFilterCount: Int
    var onFilterTap: () -> Void
    var onSubmit: () -> Void

    var body: some View {
        MegrumGlassGroup(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
            HStack(spacing: SearchLayoutMetrics.footerGlassGroupSpacing) {
                Button(action: onFilterTap) {
                    SearchFilterIconButtonContent(activeFilterCount: activeFilterCount)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索フィルター")

                SearchInputBar(query: $query, onSubmit: onSubmit)

                Button(action: onSubmit) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(.white.opacity(0.76), lineWidth: 1))
                        .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 16, y: 8)
                        .megrumLiquidGlass(.circle, tint: MegrumTheme.pink.opacity(0.16), interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索する")
            }
        }
    }
}

private struct SearchFilterIconButtonContent: View {
    var activeFilterCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 62, height: 62)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
                .megrumLiquidGlass(.circle, tint: MegrumTheme.lavender.opacity(0.14), interactive: true)
                .zIndex(SearchFilterBadgeLayering.surfaceZIndex)

            if activeFilterCount > 0 {
                SearchFilterCountBadge(count: activeFilterCount)
                    .offset(x: 8, y: -8)
                    .zIndex(SearchFilterBadgeLayering.badgeZIndex)
            }
        }
        .frame(width: 74, height: 74, alignment: .center)
        .contentShape(Circle())
    }
}

private struct SearchFilterCountBadge: View {
    var count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 23, height: 23)
            .background(MegrumTheme.lavender, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1.4))
            .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 6, y: 3)
            .allowsHitTesting(false)
    }
}

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
