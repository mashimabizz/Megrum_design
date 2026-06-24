import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState
    var initialCriteria: SearchInitialCriteria? = nil
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var onRequestInterstitial: (AdPlacement) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) private var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) private var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @State private var query = ""
    @State private var queryDraft = ""
    @State private var selectedGroupID: UUID?
    @State private var selectedMemberID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var selectedGoodsTagNames: Set<String> = []
    @State private var selectedPaymentMethods: Set<UserPaymentMethod> = []
    @State private var selectedExchangeMethod: ExchangeMethod?
    @State private var selectedMeetupDates: [Date] = []
    @State private var meetupDateDraft = Date()
    @State private var selectedMeetupPrefecture = ""
    @State private var meetupPlaceMemo = ""
    @State private var shippingFee = ""
    @State private var shippingWindow = ""
    @State private var allowsOutOfConditionProposal = false
    @State private var conditionMatches = SearchConditionMatchFilters()
    @State private var selectedSort: SearchResultSort = .newest
    @State private var isApplyingSuggestion = false
    @State private var searchTask: Task<Void, Never>?
    @State private var appliedInitialCriteriaID: String?
    @State private var proposalTargetItem: GoodsItem?
    @State private var profileRoute: PublicProfileRoute?
    @State private var isShowingFilters = false
    @State private var lastWishSuggestionHorizontalScrollDate: Date?

    private var resultCount: Int {
        filteredSearchResults.count
    }

    private var hasSearchCriteria: Bool {
        SearchCriteriaResolver.hasCriteria(query: query, activeFilterCount: activeFilterCount)
    }

    private func results(in bucket: SearchMatchBucket) -> [SearchResultItem] {
        filteredSearchResults.filter { $0.bucket == bucket }
    }

    private var filteredSearchResults: [SearchResultItem] {
        let filtered = SearchResultFilterPolicy.filteredResults(
            appState.searchResults,
            selectedMemberID: selectedMemberID,
            selectedGoodsTypeID: resolvedGoodsTypeID,
            selectedGoodsTagNames: resolvedGoodsTagNames,
            selectedPaymentMethods: selectedPaymentMethods,
            selectedExchangeMethod: selectedExchangeMethod,
            selectedMeetupPrefecture: selectedMeetupPrefecture,
            conditionMatches: conditionMatches,
            wishes: appState.wishes,
            listings: searchRelevantListings,
            viewerInventory: viewerInventoryForMatching,
            viewer: appState.viewer
        )
        return SearchResultFilterPolicy.sortedResults(filtered, sort: selectedSort)
    }

    private var queryMatchedGoodsTypeID: UUID? {
        guard selectedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingGoodsTypeID(query: query, goodsTypes: appState.goodsTypes)
    }

    private var queryMatchedTagName: String? {
        guard queryMatchedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingTagName(query: query, tagNames: availableGoodsTagNames)
    }

    private var resolvedGoodsTypeID: UUID? {
        selectedGoodsTypeID ?? queryMatchedGoodsTypeID
    }

    private var resolvedGoodsTagNames: Set<String> {
        guard let queryMatchedTagName else {
            return selectedGoodsTagNames
        }
        var tagNames = selectedGoodsTagNames
        tagNames.insert(queryMatchedTagName)
        return tagNames
    }

    private var selectedGroup: OshiGroup? {
        guard let selectedGroupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    private var selectedMember: OshiCharacter? {
        guard let selectedMemberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == selectedMemberID }
    }

    private var selectedGoodsType: GoodsType? {
        guard let selectedGoodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == selectedGoodsTypeID }
    }

    private var availableGoodsTagNames: [String] {
        SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: appState.userOshiSelections,
            wishes: appState.wishes,
            inventory: appState.inventory,
            viewerID: appState.viewer?.id,
            limitingToGroupID: selectedGroupID,
            limit: 20
        )
    }

    private var viewerInventoryForMatching: [GoodsItem] {
        guard let viewerID = appState.viewer?.id else {
            return []
        }
        return appState.inventory.filter { $0.ownerID == viewerID }
    }

    private var searchRelevantListings: [IndividualListing] {
        let resultOwnerIDs = Set(appState.searchResults.map(\.ownerUserID))
        var listings = resultOwnerIDs.flatMap { appState.publicListingsByUserID[$0] ?? [] }
        listings.append(contentsOf: appState.listings.filter { resultOwnerIDs.contains($0.ownerID) })

        var seenIDs = Set<UUID>()
        return listings.filter { listing in
            seenIDs.insert(listing.id).inserted
        }
    }

    private var currentFilterDraft: SearchFilterDraft {
        SearchFilterDraft(
            selectedGroupID: selectedGroupID,
            selectedMemberID: selectedMemberID,
            selectedGoodsTypeID: selectedGoodsTypeID,
            selectedGoodsTagNames: selectedGoodsTagNames,
            selectedPaymentMethods: selectedPaymentMethods,
            selectedExchangeMethod: selectedExchangeMethod,
            selectedMeetupDates: selectedMeetupDates,
            meetupDateDraft: meetupDateDraft,
            selectedMeetupPrefecture: selectedMeetupPrefecture,
            meetupPlaceMemo: meetupPlaceMemo,
            shippingFee: shippingFee,
            shippingWindow: shippingWindow,
            allowsOutOfConditionProposal: allowsOutOfConditionProposal,
            conditionMatches: conditionMatches
        )
    }

    private var currentDefaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap
        )
    }

    private var currentDefaultPaymentMethods: [UserPaymentMethod] {
        UserPaymentMethod.normalized(appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [])
    }

    private var activeFilterCount: Int {
        var count = 0
        if selectedGroupID != nil { count += 1 }
        if selectedMemberID != nil { count += 1 }
        if selectedGoodsTypeID != nil { count += 1 }
        count += selectedGoodsTagNames.count
        count += selectedPaymentMethods.count
        if selectedExchangeMethod != nil { count += 1 }
        if !selectedMeetupDates.isEmpty { count += 1 }
        if !selectedMeetupPrefecture.isEmpty { count += 1 }
        if !meetupPlaceMemo.isBlank { count += 1 }
        if !shippingFee.isBlank { count += 1 }
        if !shippingWindow.isBlank { count += 1 }
        if allowsOutOfConditionProposal { count += 1 }
        count += conditionMatches.activeCount
        return count
    }

    private var activeCriteriaChips: [SearchActiveCriteriaChipItem] {
        SearchActiveCriteriaChipBuilder.chips(
            query: query,
            selectedGroup: selectedGroup,
            selectedMember: selectedMember,
            selectedGoodsType: selectedGoodsType,
            selectedGoodsTagNames: selectedGoodsTagNames,
            selectedPaymentMethods: selectedPaymentMethods,
            selectedExchangeMethod: selectedExchangeMethod,
            selectedMeetupDates: selectedMeetupDates,
            selectedMeetupPrefecture: selectedMeetupPrefecture,
            meetupPlaceMemo: meetupPlaceMemo,
            shippingFee: shippingFee,
            shippingWindow: shippingWindow,
            allowsOutOfConditionProposal: allowsOutOfConditionProposal,
            conditionMatches: conditionMatches
        )
    }

    private var searchSuggestionSections: [SearchSuggestionSection] {
        SearchSuggestionBuilder.sections(
            userOshiSelections: appState.userOshiSelections,
            oshiGroups: appState.oshiGroups,
            oshiCharacters: appState.oshiCharacters,
            wishes: appState.wishes,
            inventory: appState.inventory,
            viewer: appState.viewer
        )
    }

    private var selectedSuggestionActions: Set<SearchSuggestionAction> {
        var actions = Set<SearchSuggestionAction>()
        if let selectedGroupID {
            actions.insert(.group(selectedGroupID))
        }
        if let selectedGroupID, let selectedMemberID {
            actions.insert(.member(groupID: selectedGroupID, memberID: selectedMemberID))
        }
        if let selectedGoodsTypeID {
            actions.insert(.goodsType(selectedGoodsTypeID))
        }
        for tagName in selectedGoodsTagNames {
            actions.insert(.tag(tagName))
        }
        for method in selectedPaymentMethods {
            actions.insert(.payment(method))
        }
        if !selectedMeetupPrefecture.isEmpty {
            actions.insert(.meetupPrefecture(selectedMeetupPrefecture))
        }
        return actions
    }

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

    private var searchBackSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard SearchBackSwipeResolver.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    isSuppressedByNestedHorizontalScroll: SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(
                        lastNestedHorizontalScrollDate: lastWishSuggestionHorizontalScrollDate
                    )
                ) else {
                    return
                }
                dismiss()
            }
    }

    private func loadFiltersAndSearch() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        if appState.paymentSettings == nil {
            await appState.loadPaymentSettings()
        }
        if appState.userOshiSelections.isEmpty {
            await appState.loadUserOshiSelections()
        }
        if appState.listings.isEmpty {
            await appState.loadIndividualListings()
        }
        await applyInitialCriteriaIfNeeded()
        await searchIfNeeded()
    }

    private func applyInitialCriteriaIfNeeded() async {
        guard let initialCriteria,
              appliedInitialCriteriaID != initialCriteria.id
        else {
            return
        }
        appliedInitialCriteriaID = initialCriteria.id
        query = initialCriteria.query
        queryDraft = initialCriteria.query
        selectedGroupID = initialCriteria.groupID
        selectedMemberID = initialCriteria.memberID
        selectedGoodsTypeID = initialCriteria.goodsTypeID
        selectedGoodsTagNames = Set(initialCriteria.tagNames)
        if selectedGroupID != nil {
            await appState.loadOshiCharacters(group: selectedGroup)
        }
    }

    private func searchIfNeeded() async {
        guard hasSearchCriteria else {
            return
        }
        let matchedGoodsTypeID = queryMatchedGoodsTypeID
        let matchedTagName = queryMatchedTagName
        await appState.searchGoods(
            query: SearchQueryResolver.backendQuery(
                query: query,
                matchedGoodsTypeID: matchedGoodsTypeID,
                matchedTagName: matchedTagName
            ),
            groupID: selectedGroupID,
            memberID: selectedMemberID,
            goodsTypeID: selectedGoodsTypeID ?? matchedGoodsTypeID
        )
        await loadSearchResultOwnerExchangeContentIfNeeded()
    }

    private func reportItem(_ item: GoodsItem, reason: GoodsReportReason, note: String) {
        Task {
            _ = await appState.reportGoods(
                itemID: item.id,
                reportedUserID: item.ownerID,
                reason: reason,
                note: note
            )
        }
    }

    private func scheduleSearch(delayNanoseconds: UInt64 = 260_000_000) {
        searchTask?.cancel()
        guard hasSearchCriteria else {
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else {
                return
            }
            await searchIfNeeded()
        }
    }

    private func submitSearch() {
        query = queryDraft
        scheduleSearch(delayNanoseconds: 0)
    }

    private func resetFilters() {
        selectedGroupID = nil
        selectedMemberID = nil
        selectedGoodsTypeID = nil
        selectedGoodsTagNames = []
        selectedPaymentMethods = []
        selectedExchangeMethod = nil
        selectedMeetupDates = []
        selectedMeetupPrefecture = ""
        meetupPlaceMemo = ""
        shippingFee = ""
        shippingWindow = ""
        allowsOutOfConditionProposal = false
        conditionMatches = SearchConditionMatchFilters()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
        scheduleSearch(delayNanoseconds: 0)
    }

    private func removeActiveCriteria(_ removal: SearchActiveCriteriaRemoval) {
        switch removal {
        case .query:
            query = ""
            queryDraft = ""
        case .group:
            selectedGroupID = nil
            selectedMemberID = nil
        case .member:
            selectedMemberID = nil
        case .goodsType:
            selectedGoodsTypeID = nil
        case .goodsTag(let tagName):
            selectedGoodsTagNames.remove(tagName)
        case .paymentMethod(let method):
            selectedPaymentMethods.remove(method)
        case .exchangeMethod:
            selectedExchangeMethod = nil
        case .meetupDates:
            selectedMeetupDates = []
        case .meetupPrefecture:
            selectedMeetupPrefecture = ""
        case .meetupPlaceMemo:
            meetupPlaceMemo = ""
        case .shippingFee:
            shippingFee = ""
        case .shippingWindow:
            shippingWindow = ""
        case .allowsOutOfConditionProposal:
            allowsOutOfConditionProposal = false
        case .conditionMatch(let kind):
            switch kind {
            case .wish:
                conditionMatches.matchesWish = false
            case .individualListing:
                conditionMatches.matchesIndividualListing = false
            case .exchangeCondition:
                conditionMatches.matchesExchangeCondition = false
            case .paymentCondition:
                conditionMatches.matchesPaymentCondition = false
            }
        }
        scheduleSearch(delayNanoseconds: 0)
    }

    private func applyFilterDraft(_ draft: SearchFilterDraft) {
        selectedGroupID = draft.selectedGroupID
        selectedMemberID = draft.selectedMemberID
        selectedGoodsTypeID = draft.selectedGoodsTypeID
        selectedGoodsTagNames = draft.selectedGoodsTagNames
        selectedPaymentMethods = draft.selectedPaymentMethods
        selectedExchangeMethod = draft.selectedExchangeMethod
        selectedMeetupDates = draft.selectedMeetupDates
        meetupDateDraft = draft.meetupDateDraft
        selectedMeetupPrefecture = draft.selectedMeetupPrefecture
        meetupPlaceMemo = draft.meetupPlaceMemo
        shippingFee = draft.shippingFee
        shippingWindow = draft.shippingWindow
        allowsOutOfConditionProposal = draft.allowsOutOfConditionProposal
        conditionMatches = draft.conditionMatches
        Task {
            await appState.loadOshiCharacters(group: selectedGroup)
        }
    }

    private func loadSearchResultOwnerExchangeContentIfNeeded() async {
        guard conditionMatches.matchesIndividualListing else {
            return
        }
        let viewerID = appState.viewer?.id
        let ownerIDs = Set(appState.searchResults.map(\.ownerUserID)).filter { $0 != viewerID }
        for ownerID in ownerIDs where appState.publicListingsByUserID[ownerID] == nil {
            await appState.loadPublicExchangeContent(userID: ownerID)
        }
    }

    private func markWishSuggestionHorizontalScroll() {
        lastWishSuggestionHorizontalScrollDate = Date()
    }

    private func applyConditionMatchDefaults(
        previous: SearchConditionMatchFilters,
        current: SearchConditionMatchFilters
    ) {
        if current.matchesExchangeCondition, !previous.matchesExchangeCondition {
            applyDefaultExchangeCondition()
        }
        if current.matchesPaymentCondition, !previous.matchesPaymentCondition {
            applyDefaultPaymentCondition()
        }
    }

    private func applyDefaultExchangeCondition() {
        let settings = HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap
        )
        switch settings.preference {
        case .local:
            selectedExchangeMethod = .hand
        case .mail:
            selectedExchangeMethod = .mail
        case .both:
            selectedExchangeMethod = .both
        }

        if settings.requiresSamePrefecture,
           let prefecture = appState.viewer?.prefecture,
           !prefecture.isBlank {
            selectedMeetupPrefecture = prefecture
        }
    }

    private func applyDefaultPaymentCondition() {
        let methods = UserPaymentMethod.normalized(
            appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? []
        )
        if !methods.isEmpty {
            selectedPaymentMethods = Set(methods)
        }
    }

    private func applySuggestion(_ action: SearchSuggestionAction) {
        isApplyingSuggestion = true
        switch action {
        case .group(let groupID):
            selectedGroupID = groupID
            selectedMemberID = nil
        case .member(let groupID, let memberID):
            selectedGroupID = groupID
            selectedMemberID = memberID
        case .wish(let groupID, let memberID, let goodsTypeID, let tagNames):
            selectedGroupID = groupID
            selectedMemberID = memberID
            selectedGoodsTypeID = goodsTypeID
            if groupID == nil, memberID == nil, goodsTypeID == nil {
                selectedGoodsTagNames.formUnion(
                    SearchSuggestionTagPolicy.allowedRequestedTagNames(
                        tagNames,
                        candidateTagNames: availableGoodsTagNames
                    )
                )
            }
            conditionMatches.matchesWish = true
        case .goodsType(let goodsTypeID):
            selectedGoodsTypeID = goodsTypeID
        case .tag(let tagName):
            selectedGoodsTagNames.insert(tagName)
        case .payment(let method):
            selectedPaymentMethods.insert(method)
        case .meetupPrefecture(let prefecture):
            selectedMeetupPrefecture = prefecture
        case .query(let text):
            query = text
            queryDraft = text
        }
        scheduleSearch(delayNanoseconds: 0)
        finishSuggestionApplication()
    }

    private func finishSuggestionApplication() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            isApplyingSuggestion = false
        }
    }
}
