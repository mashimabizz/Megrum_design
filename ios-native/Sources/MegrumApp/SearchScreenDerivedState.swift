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
            selectedMemberIDs: filterDraft.selectedMemberIDs,
            selectedGoodsTypeIDs: resolvedGoodsTypeIDs,
            selectedGoodsTagNames: resolvedGoodsTagNames,
            selectedPaymentMethods: filterDraft.selectedPaymentMethods,
            selectedExchangeMethod: filterDraft.selectedExchangeMethod,
            selectedMeetupPrefecture: filterDraft.selectedMeetupPrefecture,
            wantsMyGoodsOnly: filterDraft.wantsMyGoodsOnly,
            wantsCashOK: filterDraft.wantsCashOK,
            listings: searchRelevantListings,
            viewerInventory: viewerInventoryForMatching
        )
        return SearchResultFilterPolicy.sortedResults(filtered, sort: presentationState.selectedSort)
    }

    var queryMatchedGoodsTypeID: UUID? {
        guard filterDraft.selectedGoodsTypeIDs.isEmpty else {
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

    var resolvedGoodsTypeIDs: Set<UUID> {
        if !filterDraft.selectedGoodsTypeIDs.isEmpty {
            return filterDraft.selectedGoodsTypeIDs
        }
        return queryMatchedGoodsTypeID.map { Set([$0]) } ?? []
    }

    var resolvedGoodsTagNames: Set<String> {
        guard let queryMatchedTagName else {
            return filterDraft.selectedGoodsTagNames
        }
        var tagNames = filterDraft.selectedGoodsTagNames
        tagNames.insert(queryMatchedTagName)
        return tagNames
    }

    var selectedGroups: [OshiGroup] {
        appState.oshiGroups.filter { filterDraft.selectedGroupIDs.contains($0.id) }
    }

    var selectedGroup: OshiGroup? {
        selectedGroups.first
    }

    var selectedMembers: [OshiCharacter] {
        appState.oshiCharacters.filter { filterDraft.selectedMemberIDs.contains($0.id) }
    }

    var selectedGoodsTypes: [GoodsType] {
        appState.goodsTypes.filter { filterDraft.selectedGoodsTypeIDs.contains($0.id) }
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
        if filterDraft.wantsMyGoodsOnly { count += 1 }
        if filterDraft.wantsCashOK { count += 1 }
        return count
    }

    var activeCriteriaChips: [SearchActiveCriteriaChipItem] {
        SearchActiveCriteriaChipBuilder.chips(
            query: presentationState.query,
            selectedGroupNames: selectedGroups.map(\.name),
            selectedMemberNames: selectedMembers.map(\.name),
            selectedGoodsTypeNames: selectedGoodsTypes.map(\.name),
            selectedGoodsTagNames: filterDraft.selectedGoodsTagNames,
            selectedPaymentMethods: filterDraft.selectedPaymentMethods,
            selectedExchangeMethod: filterDraft.selectedExchangeMethod,
            selectedMeetupDates: filterDraft.selectedMeetupDates,
            selectedMeetupPrefecture: filterDraft.selectedMeetupPrefecture,
            meetupPlaceMemo: filterDraft.meetupPlaceMemo,
            shippingFee: filterDraft.shippingFee,
            shippingWindow: filterDraft.shippingWindow,
            allowsOutOfConditionProposal: filterDraft.allowsOutOfConditionProposal,
            wantsMyGoodsOnly: filterDraft.wantsMyGoodsOnly,
            wantsCashOK: filterDraft.wantsCashOK
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
