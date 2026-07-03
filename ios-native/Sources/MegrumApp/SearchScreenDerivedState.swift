import Foundation
import MegrumCore

extension SearchScreen {
    var resultCount: Int {
        filteredSearchResults.count
    }

    var hasSearchCriteria: Bool {
        SearchCriteriaResolver.hasCriteria(query: presentationState.query, activeFilterCount: activeFilterCount)
    }

    func results(in bucket: SearchMatchBucket) -> [SearchResultItem] {
        filteredSearchResults.filter { $0.bucket == bucket }
    }

    var filteredSearchResults: [SearchResultItem] {
        let filtered = SearchResultFilterPolicy.filteredResults(
            appState.searchResults,
            selectedMemberID: filterDraft.selectedMemberID,
            selectedGoodsTypeID: resolvedGoodsTypeID,
            selectedGoodsTagNames: resolvedGoodsTagNames,
            selectedPaymentMethods: filterDraft.selectedPaymentMethods,
            selectedExchangeMethod: filterDraft.selectedExchangeMethod,
            selectedMeetupPrefecture: filterDraft.selectedMeetupPrefecture,
            conditionMatches: filterDraft.conditionMatches,
            wishes: appState.wishes,
            listings: searchRelevantListings,
            viewerInventory: viewerInventoryForMatching,
            viewer: appState.viewer
        )
        return SearchResultFilterPolicy.sortedResults(filtered, sort: presentationState.selectedSort)
    }

    var queryMatchedGoodsTypeID: UUID? {
        guard filterDraft.selectedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingGoodsTypeID(query: presentationState.query, goodsTypes: appState.goodsTypes)
    }

    var queryMatchedTagName: String? {
        guard queryMatchedGoodsTypeID == nil else {
            return nil
        }
        return SearchQueryResolver.matchingTagName(query: presentationState.query, tagNames: availableGoodsTagNames)
    }

    var resolvedGoodsTypeID: UUID? {
        filterDraft.selectedGoodsTypeID ?? queryMatchedGoodsTypeID
    }

    var resolvedGoodsTagNames: Set<String> {
        guard let queryMatchedTagName else {
            return filterDraft.selectedGoodsTagNames
        }
        var tagNames = filterDraft.selectedGoodsTagNames
        tagNames.insert(queryMatchedTagName)
        return tagNames
    }

    var selectedGroup: OshiGroup? {
        guard let selectedGroupID = filterDraft.selectedGroupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    var selectedMember: OshiCharacter? {
        guard let selectedMemberID = filterDraft.selectedMemberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == selectedMemberID }
    }

    var selectedGoodsType: GoodsType? {
        guard let selectedGoodsTypeID = filterDraft.selectedGoodsTypeID else {
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
            limitingToGroupID: filterDraft.selectedGroupID,
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
        filterDraft
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
        PaymentSettingsResolver.methods(settings: appState.paymentSettings, viewer: appState.viewer)
    }

    var activeFilterCount: Int {
        var count = 0
        if filterDraft.selectedGroupID != nil { count += 1 }
        if filterDraft.selectedMemberID != nil { count += 1 }
        if filterDraft.selectedGoodsTypeID != nil { count += 1 }
        count += filterDraft.selectedGoodsTagNames.count
        count += filterDraft.selectedPaymentMethods.count
        if filterDraft.selectedExchangeMethod != nil { count += 1 }
        if !filterDraft.selectedMeetupDates.isEmpty { count += 1 }
        if !filterDraft.selectedMeetupPrefecture.isEmpty { count += 1 }
        if !filterDraft.meetupPlaceMemo.isBlank { count += 1 }
        if !filterDraft.shippingFee.isBlank { count += 1 }
        if !filterDraft.shippingWindow.isBlank { count += 1 }
        if filterDraft.allowsOutOfConditionProposal { count += 1 }
        count += filterDraft.conditionMatches.activeCount
        return count
    }

    var activeCriteriaChips: [SearchActiveCriteriaChipItem] {
        SearchActiveCriteriaChipBuilder.chips(
            query: presentationState.query,
            selectedGroup: selectedGroup,
            selectedMember: selectedMember,
            selectedGoodsType: selectedGoodsType,
            selectedGoodsTagNames: filterDraft.selectedGoodsTagNames,
            selectedPaymentMethods: filterDraft.selectedPaymentMethods,
            selectedExchangeMethod: filterDraft.selectedExchangeMethod,
            selectedMeetupDates: filterDraft.selectedMeetupDates,
            selectedMeetupPrefecture: filterDraft.selectedMeetupPrefecture,
            meetupPlaceMemo: filterDraft.meetupPlaceMemo,
            shippingFee: filterDraft.shippingFee,
            shippingWindow: filterDraft.shippingWindow,
            allowsOutOfConditionProposal: filterDraft.allowsOutOfConditionProposal,
            conditionMatches: filterDraft.conditionMatches
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
        if let selectedGroupID = filterDraft.selectedGroupID {
            actions.insert(.group(selectedGroupID))
        }
        if let selectedGroupID = filterDraft.selectedGroupID,
           let selectedMemberID = filterDraft.selectedMemberID {
            actions.insert(.member(groupID: selectedGroupID, memberID: selectedMemberID))
        }
        if let selectedGoodsTypeID = filterDraft.selectedGoodsTypeID {
            actions.insert(.goodsType(selectedGoodsTypeID))
        }
        for tagName in filterDraft.selectedGoodsTagNames {
            actions.insert(.tag(tagName))
        }
        for method in filterDraft.selectedPaymentMethods {
            actions.insert(.payment(method))
        }
        if !filterDraft.selectedMeetupPrefecture.isEmpty {
            actions.insert(.meetupPrefecture(filterDraft.selectedMeetupPrefecture))
        }
        return actions
    }
}
