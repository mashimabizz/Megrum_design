import Foundation
import MegrumCore
import SwiftUI

extension SearchScreen {
    var searchBackSwipeGesture: some Gesture {
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

    func searchIfNeeded() async {
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
        query = queryDraft
        scheduleSearch(delayNanoseconds: 0)
    }

    func resetFilters() {
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

    func removeActiveCriteria(_ removal: SearchActiveCriteriaRemoval) {
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

    func applyFilterDraft(_ draft: SearchFilterDraft) {
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

    func loadSearchResultOwnerExchangeContentIfNeeded() async {
        guard conditionMatches.matchesIndividualListing else {
            return
        }
        let viewerID = appState.viewer?.id
        let ownerIDs = Set(appState.searchResults.map(\.ownerUserID)).filter { $0 != viewerID }
        for ownerID in ownerIDs where appState.publicListingsByUserID[ownerID] == nil {
            await appState.loadPublicExchangeContent(userID: ownerID)
        }
    }

    func markWishSuggestionHorizontalScroll() {
        lastWishSuggestionHorizontalScrollDate = Date()
    }

    func applyConditionMatchDefaults(
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

    func applyDefaultExchangeCondition() {
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

    func applyDefaultPaymentCondition() {
        let methods = UserPaymentMethod.normalized(
            appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? []
        )
        if !methods.isEmpty {
            selectedPaymentMethods = Set(methods)
        }
    }

    func applySuggestion(_ action: SearchSuggestionAction) {
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

    func finishSuggestionApplication() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            isApplyingSuggestion = false
        }
    }
}
