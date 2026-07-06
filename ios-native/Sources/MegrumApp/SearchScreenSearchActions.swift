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
            groupIDs: Array(filterDraft.selectedGroupIDs),
            memberIDs: Array(filterDraft.selectedMemberIDs),
            goodsTypeIDs: filterDraft.selectedGoodsTypeIDs.isEmpty
                ? (matchedGoodsTypeID.map { [$0] } ?? [])
                : Array(filterDraft.selectedGoodsTypeIDs)
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
        // 需要行の表示に相手の個別募集情報を使うため、結果の持ち主の交換情報を常に読み込む
        let viewerID = appState.viewer?.id
        let ownerIDs = Set(appState.searchResults.map(\.ownerUserID)).filter { $0 != viewerID }
        for ownerID in ownerIDs where appState.publicListingsByUserID[ownerID] == nil {
            await appState.loadPublicExchangeContent(userID: ownerID)
        }
    }
}
