import Foundation
import MegrumCore

extension SearchScreen {
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
}
