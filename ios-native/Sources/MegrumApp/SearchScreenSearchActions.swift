import Foundation
import MegrumCore

extension SearchScreen {
    func loadFiltersAndSearch() async {
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

    func applyInitialCriteriaIfNeeded() async {
        let didApplyInitialCriteria = presentationState.applyInitialCriteriaIfNeeded(
            initialCriteria,
            filterDraft: &filterDraft
        )
        guard didApplyInitialCriteria else {
            return
        }
        if filterDraft.selectedGroupID != nil {
            await appState.loadOshiCharacters(group: selectedGroup)
        }
    }

    func searchIfNeeded() async {
        guard hasSearchCriteria else {
            return
        }
        let matchedGoodsTypeID = queryMatchedGoodsTypeID
        let matchedTagName = queryMatchedTagName
        await appState.searchGoods(
            query: SearchQueryResolver.backendQuery(
                query: presentationState.query,
                matchedGoodsTypeID: matchedGoodsTypeID,
                matchedTagName: matchedTagName
            ),
            groupID: filterDraft.selectedGroupID,
            memberID: filterDraft.selectedMemberID,
            goodsTypeID: filterDraft.selectedGoodsTypeID ?? matchedGoodsTypeID
        )
        await loadSearchResultOwnerExchangeContentIfNeeded()
    }

    func reportItem(_ item: GoodsItem, reason: GoodsReportReason, note: String) {
        Task {
            _ = await appState.reportGoods(
                itemID: item.id,
                reportedUserID: item.ownerID,
                reason: reason,
                note: note
            )
        }
    }

    func scheduleSearch(delayNanoseconds: UInt64 = 260_000_000) {
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

    func submitSearch() {
        presentationState.submitQuery()
        scheduleSearch(delayNanoseconds: 0)
    }

    func loadSearchResultOwnerExchangeContentIfNeeded() async {
        guard filterDraft.conditionMatches.matchesIndividualListing else {
            return
        }
        let viewerID = appState.viewer?.id
        let ownerIDs = Set(appState.searchResults.map(\.ownerUserID)).filter { $0 != viewerID }
        for ownerID in ownerIDs where appState.publicListingsByUserID[ownerID] == nil {
            await appState.loadPublicExchangeContent(userID: ownerID)
        }
    }
}
