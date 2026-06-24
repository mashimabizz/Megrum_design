import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState
    var initialCriteria: SearchInitialCriteria? = nil
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onRequestInterstitial: (AdPlacement) -> Void = { _ in }

    @Environment(\.dismiss) var dismiss
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @State var query = ""
    @State var queryDraft = ""
    @State var selectedGroupID: UUID?
    @State var selectedMemberID: UUID?
    @State var selectedGoodsTypeID: UUID?
    @State var selectedGoodsTagNames: Set<String> = []
    @State var selectedPaymentMethods: Set<UserPaymentMethod> = []
    @State var selectedExchangeMethod: ExchangeMethod?
    @State var selectedMeetupDates: [Date] = []
    @State var meetupDateDraft = Date()
    @State var selectedMeetupPrefecture = ""
    @State var meetupPlaceMemo = ""
    @State var shippingFee = ""
    @State var shippingWindow = ""
    @State var allowsOutOfConditionProposal = false
    @State var conditionMatches = SearchConditionMatchFilters()
    @State var selectedSort: SearchResultSort = .newest
    @State var isApplyingSuggestion = false
    @State var searchTask: Task<Void, Never>?
    @State var appliedInitialCriteriaID: String?
    @State var proposalTargetItem: GoodsItem?
    @State var profileRoute: PublicProfileRoute?
    @State var isShowingFilters = false
    @State var lastWishSuggestionHorizontalScrollDate: Date?

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
                sort: $selectedSort,
                appState: appState,
                viewerID: appState.viewer?.id,
                adDisplayContext: adDisplayContext,
                onBack: {
                    dismiss()
                },
                onRemoveActiveCriteria: removeActiveCriteria,
                onFilterTap: {
                    isShowingFilters = true
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
                query: $queryDraft,
                activeFilterCount: activeFilterCount,
                onFilterTap: {
                    isShowingFilters = true
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
        .simultaneousGesture(searchBackSwipeGesture, including: .gesture)
        .task {
            await loadFiltersAndSearch()
            onRequestInterstitial(.searchBrowseInterstitial)
        }
        .onChange(of: selectedGroupID) { _, newValue in
            if newValue == nil {
                selectedMemberID = nil
            }
            Task {
                await appState.loadOshiCharacters(group: selectedGroup)
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .sheet(item: $proposalTargetItem) { item in
            NavigationStack {
                ProposalCreateFlow(appState: appState, targetItem: item)
            }
        }
        .sheet(item: $profileRoute) { route in
            NavigationStack {
                PublicUserProfileScreen(
                    appState: appState,
                    userID: route.userID,
                    adDisplayContext: adDisplayContext,
                    adPlacement: .publicProfileFooterBanner
                )
            }
        }
        .sheet(isPresented: $isShowingFilters) {
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
