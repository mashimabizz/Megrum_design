import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState
    var initialCriteria: SearchInitialCriteria? = nil
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onRequestInterstitial: (AdPlacement) -> Void = { _ in }
    var onDismissRequest: (() -> Void)?

    @Environment(\.dismiss) var dismiss
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @State var presentationState = SearchScreenPresentationState()
    @State var filterDraft = SearchFilterDraft()
    @State var searchTask: Task<Void, Never>?
    @State var proposalTargetItem: GoodsItem?
    @State var profileRoute: PublicProfileRoute?
    @State var showsWishPicker = false
    @State var showsListingPicker = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SearchContent(
                activeFilterCount: activeFilterCount,
                activeCriteriaChips: activeCriteriaChips,
                hasSearchCriteria: hasSearchCriteria,
                resultCount: resultCount,
                isSearching: appState.isSearchingGoods,
                isSearchResultsEmpty: appState.searchResults.isEmpty,
                results: filteredSearchResults,
                suggestionSections: searchSuggestionSections,
                selectedSuggestionActions: selectedSuggestionActions,
                sort: $presentationState.selectedSort,
                appState: appState,
                viewerID: appState.viewer?.id,
                adDisplayContext: adDisplayContext,
                onBack: {
                    closeSearch()
                },
                onRemoveActiveCriteria: removeActiveCriteria,
                onFilterTap: {
                    presentationState.showFilters()
                },
                showsWishEntry: !appState.wishes.isEmpty,
                showsListingEntry: appState.listings.contains { $0.status == .active },
                onOpenWishPicker: {
                    showsWishPicker = true
                },
                onOpenListingPicker: {
                    showsListingPicker = true
                },
                onSelectSuggestion: applySuggestion,
                onWishSuggestionHorizontalDrag: markWishSuggestionHorizontalScroll,
                onStartProposal: { item in
                    proposalTargetItem = item
                },
                onOpenOwnerProfile: { userID in
                    profileRoute = PublicProfileRoute(userID: userID)
                },
                onReportItem: { item, reason, note in
                    reportItem(item, reason: reason, note: note)
                }
            )

            SearchFooterBar(
                query: $presentationState.queryDraft,
                activeFilterCount: activeFilterCount,
                onFilterTap: {
                    presentationState.showFilters()
                }
            ) {
                submitSearch()
            }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .searchScreenTabBarVisibility()
        .megrumInteractiveBackSwipe(
            isSuppressed: {
                presentationState.isBackSwipeSuppressed()
            },
            action: {
                closeSearch()
            }
        )
        .task {
            await loadFiltersAndSearch()
            onRequestInterstitial(.searchBrowseInterstitial)
        }
        .onChange(of: filterDraft.selectedGroupIDs) { _, newValue in
            if newValue.isEmpty {
                filterDraft.selectedMemberIDs = []
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .sheet(isPresented: $showsWishPicker) {
            SearchWishPickerSheet(wishes: appState.wishes) { action in
                applySuggestion(action)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsListingPicker) {
            SearchListingPickerSheet(
                listings: appState.listings,
                wishes: appState.wishes,
                inventory: appState.inventory,
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes,
                characters: appState.oshiCharacters,
                onSelect: applyListingSearchCriteria
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .megrumSlideItemPresentation(item: $proposalTargetItem) { item, _ in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .megrumSlideItemPresentation(item: $profileRoute) { route, _ in
            NavigationStack {
                PublicUserProfileScreen(
                    appState: appState,
                    userID: route.userID,
                    adDisplayContext: adDisplayContext,
                    adPlacement: .publicProfileFooterBanner
                )
            }
        }
        .sheet(isPresented: $presentationState.isShowingFilters) {
            NavigationStack {
                SearchFilterSheet(
                    appState: appState,
                    initialDraft: currentFilterDraft,
                    defaultExchangeSettings: currentDefaultExchangeSettings,
                    defaultPaymentMethods: currentDefaultPaymentMethods,
                    onApply: { draft in
                        applyFilterDraft(draft)
                        scheduleSearch(delayNanoseconds: 0)
                    }
                )
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }
}
