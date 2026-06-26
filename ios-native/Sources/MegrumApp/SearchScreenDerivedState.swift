import Foundation
import MegrumCore

extension SearchScreen {
    var resultCount: Int {
        filteredSearchResults.count
    }

    var hasSearchCriteria: Bool {
        SearchCriteriaResolver.hasCriteria(query: query, activeFilterCount: activeFilterCount)
    }

    func results(in bucket: SearchMatchBucket) -> [SearchResultItem] {
        filteredSearchResults.filter { $0.bucket == bucket }
    }

    var filteredSearchResults: [SearchResultItem] {
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

    var queryMatchedGoodsTypeID: UUID? {
        guard selectedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingGoodsTypeID(query: query, goodsTypes: appState.goodsTypes)
    }

    var queryMatchedTagName: String? {
        guard queryMatchedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingTagName(query: query, tagNames: availableGoodsTagNames)
    }

    var resolvedGoodsTypeID: UUID? {
        selectedGoodsTypeID ?? queryMatchedGoodsTypeID
    }

    var resolvedGoodsTagNames: Set<String> {
        guard let queryMatchedTagName else {
            return selectedGoodsTagNames
        }
        var tagNames = selectedGoodsTagNames
        tagNames.insert(queryMatchedTagName)
        return tagNames
    }

    var selectedGroup: OshiGroup? {
        guard let selectedGroupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    var selectedMember: OshiCharacter? {
        guard let selectedMemberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == selectedMemberID }
    }

    var selectedGoodsType: GoodsType? {
        guard let selectedGoodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == selectedGoodsTypeID }
    }

    var availableGoodsTagNames: [String] {
        SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: appState.userOshiSelections,
            wishes: appState.wishes,
            inventory: appState.inventory,
            viewerID: appState.viewer?.id,
            limitingToGroupID: selectedGroupID,
            limit: 20
        )
    }

    var viewerInventoryForMatching: [GoodsItem] {
        guard let viewerID = appState.viewer?.id else {
            return []
        }
        return appState.inventory.filter { $0.ownerID == viewerID }
    }

    var searchRelevantListings: [IndividualListing] {
        let resultOwnerIDs = Set(appState.searchResults.map(\.ownerUserID))
        var listings = resultOwnerIDs.flatMap { appState.publicListingsByUserID[$0] ?? [] }
        listings.append(contentsOf: appState.listings.filter { resultOwnerIDs.contains($0.ownerID) })

        var seenIDs = Set<UUID>()
        return listings.filter { listing in
            seenIDs.insert(listing.id).inserted
        }
    }

    var currentFilterDraft: SearchFilterDraft {
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

    var currentDefaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
    }

    var currentDefaultPaymentMethods: [UserPaymentMethod] {
        UserPaymentMethod.normalized(appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [])
    }

    var activeFilterCount: Int {
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

    var activeCriteriaChips: [SearchActiveCriteriaChipItem] {
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

    var searchSuggestionSections: [SearchSuggestionSection] {
        SearchSuggestionBuilder.sections(
            userOshiSelections: appState.userOshiSelections,
            oshiGroups: appState.oshiGroups,
            oshiCharacters: appState.oshiCharacters,
            wishes: appState.wishes,
            inventory: appState.inventory,
            viewer: appState.viewer
        )
    }

    var selectedSuggestionActions: Set<SearchSuggestionAction> {
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
}
