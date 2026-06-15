import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum SearchLayoutMetrics {
    static let titleFontSize: CGFloat = 42
    static let footerGlassGroupSpacing: CGFloat = 12
}

enum SearchCriteriaResolver {
    static func hasCriteria(query: String, activeFilterCount: Int) -> Bool {
        !query.isBlank || activeFilterCount > 0
    }
}

struct SearchScreen: View {
    @ObservedObject var appState: MegrumAppState

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedGroupID: UUID?
    @State private var selectedMemberID: UUID?
    @State private var selectedGoodsTypeID: UUID?
    @State private var selectedGoodsTagNames: Set<String> = []
    @State private var selectedMeetupDates: [Date] = []
    @State private var meetupDateDraft = Date()
    @State private var selectedMeetupPrefecture = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var proposalTargetItem: GoodsItem?
    @State private var profileRoute: PublicProfileRoute?
    @State private var isShowingFilters = false

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
        appState.searchResults.filter { result in
            if let selectedMemberID, result.item.memberID != selectedMemberID {
                return false
            }
            if !selectedGoodsTagNames.isEmpty {
                let itemTagNames = Set(result.item.tags.map(\.name))
                if !selectedGoodsTagNames.isSubset(of: itemTagNames) {
                    return false
                }
            }
            return true
        }
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
        let tags = appState.searchResults
            .filter { result in
                selectedGroupID == nil || result.item.groupID == selectedGroupID
            }
            .flatMap { $0.item.tags.map(\.name) }
        return Array(Set(tags))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .prefix(20)
            .map { $0 }
    }

    private var activeFilterCount: Int {
        var count = 0
        if selectedGroupID != nil { count += 1 }
        if selectedMemberID != nil { count += 1 }
        if selectedGoodsTypeID != nil { count += 1 }
        count += selectedGoodsTagNames.count
        if !selectedMeetupDates.isEmpty { count += 1 }
        if !selectedMeetupPrefecture.isEmpty { count += 1 }
        return count
    }

    private var filterSummaryTitles: [String] {
        var titles: [String] = []
        if let selectedGroup {
            titles.append(selectedGroup.name)
        }
        if let selectedMember {
            titles.append(selectedMember.name)
        }
        if let selectedGoodsType {
            titles.append(selectedGoodsType.name)
        }
        titles.append(contentsOf: selectedGoodsTagNames.sorted())
        if !selectedMeetupDates.isEmpty {
            titles.append("日付\(selectedMeetupDates.count)件")
        }
        if !selectedMeetupPrefecture.isEmpty {
            titles.append(selectedMeetupPrefecture)
        }
        return titles
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SearchContent(
                activeFilterCount: activeFilterCount,
                summaryTitles: filterSummaryTitles,
                hasSearchCriteria: hasSearchCriteria,
                resultCount: resultCount,
                isSearching: appState.isSearchingGoods,
                isSearchResultsEmpty: appState.searchResults.isEmpty,
                matchedResults: results(in: .matched),
                possibleResults: results(in: .possible),
                unmatchedResults: results(in: .none),
                viewerID: appState.viewer?.id,
                onBack: {
                    dismiss()
                },
                onFilterTap: {
                    isShowingFilters = true
                },
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
                query: $query,
                activeFilterCount: activeFilterCount,
                onFilterTap: {
                    isShowingFilters = true
                }
            ) {
                scheduleSearch(delayNanoseconds: 0)
            }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .task {
            await loadFiltersAndSearch()
        }
        .onChange(of: query) { _, _ in
            scheduleSearch()
        }
        .onChange(of: selectedGroupID) { _, _ in
            selectedMemberID = nil
            selectedGoodsTypeID = nil
            selectedGoodsTagNames = []
            Task {
                await appState.loadOshiCharacters(group: selectedGroup)
            }
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedGoodsTypeID) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedMemberID) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedMeetupDates) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
        }
        .onChange(of: selectedMeetupPrefecture) { _, _ in
            scheduleSearch(delayNanoseconds: 0)
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
                PublicUserProfileScreen(appState: appState, userID: route.userID)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            NavigationStack {
                SearchFilterSheet(
                    appState: appState,
                    selectedGroupID: $selectedGroupID,
                    selectedMemberID: $selectedMemberID,
                    selectedGoodsTypeID: $selectedGoodsTypeID,
                    selectedGoodsTagNames: $selectedGoodsTagNames,
                    selectedMeetupDates: $selectedMeetupDates,
                    meetupDateDraft: $meetupDateDraft,
                    selectedMeetupPrefecture: $selectedMeetupPrefecture,
                    availableGoodsTagNames: availableGoodsTagNames,
                    onReset: resetFilters
                )
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }

    private func loadFiltersAndSearch() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        await searchIfNeeded()
    }

    private func searchIfNeeded() async {
        guard hasSearchCriteria else {
            return
        }
        await appState.searchGoods(
            query: query,
            groupID: selectedGroupID,
            memberID: selectedMemberID,
            goodsTypeID: selectedGoodsTypeID
        )
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

    private func resetFilters() {
        selectedGroupID = nil
        selectedMemberID = nil
        selectedGoodsTypeID = nil
        selectedGoodsTagNames = []
        selectedMeetupDates = []
        selectedMeetupPrefecture = ""
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
        scheduleSearch(delayNanoseconds: 0)
    }
}
