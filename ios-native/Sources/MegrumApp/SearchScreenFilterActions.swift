import Foundation
import MegrumCore

extension SearchScreen {
    func resetFilters() {
        filterDraft = filterDraft.reset()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
        scheduleSearch(delayNanoseconds: 0)
    }

    func removeActiveCriteria(_ removal: SearchActiveCriteriaRemoval) {
        switch removal {
        case .query:
            presentationState.clearQuery()
        case .group:
            filterDraft.selectedGroupID = nil
            filterDraft.selectedMemberID = nil
        case .member:
            filterDraft.selectedMemberID = nil
        case .goodsType:
            filterDraft.selectedGoodsTypeID = nil
        case .goodsTag(let tagName):
            filterDraft.selectedGoodsTagNames.remove(tagName)
        case .paymentMethod(let method):
            filterDraft.selectedPaymentMethods.remove(method)
        case .exchangeMethod:
            filterDraft.selectedExchangeMethod = nil
        case .meetupDates:
            filterDraft.selectedMeetupDates = []
        case .meetupPrefecture:
            filterDraft.selectedMeetupPrefecture = ""
        case .meetupPlaceMemo:
            filterDraft.meetupPlaceMemo = ""
        case .shippingFee:
            filterDraft.shippingFee = ""
        case .shippingWindow:
            filterDraft.shippingWindow = ""
        case .allowsOutOfConditionProposal:
            filterDraft.allowsOutOfConditionProposal = false
        case .conditionMatch(let kind):
            switch kind {
            case .wish:
                filterDraft.conditionMatches.matchesWish = false
            case .individualListing:
                filterDraft.conditionMatches.matchesIndividualListing = false
            case .exchangeCondition:
                filterDraft.conditionMatches.matchesExchangeCondition = false
            case .paymentCondition:
                filterDraft.conditionMatches.matchesPaymentCondition = false
            }
        }
        scheduleSearch(delayNanoseconds: 0)
    }

    func applyFilterDraft(_ draft: SearchFilterDraft) {
        filterDraft = draft
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
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
        switch settings.preference {
        case .local:
            filterDraft.selectedExchangeMethod = .hand
        case .mail:
            filterDraft.selectedExchangeMethod = .mail
        case .both:
            filterDraft.selectedExchangeMethod = .both
        }

        if settings.requiresSamePrefecture {
            let prefecture = settings.localPrefecture.nilIfBlank ?? appState.viewer?.prefecture
            if let prefecture, !prefecture.isBlank {
                filterDraft.selectedMeetupPrefecture = prefecture
            }
        }

        let dates = settings.usableLocalDateKeys.compactMap { HomeExchangeDateKey.date(from: $0) }
        if !dates.isEmpty {
            filterDraft.selectedMeetupDates = dates
        }

        if settings.preference.acceptsMail {
            filterDraft.shippingFee = settings.mailShippingFee.title
            filterDraft.shippingWindow = settings.mailShippingDays.title
        }
    }

    func applyDefaultPaymentCondition() {
        let methods = PaymentSettingsResolver.methods(settings: appState.paymentSettings, viewer: appState.viewer)
        if !methods.isEmpty {
            filterDraft.selectedPaymentMethods = Set(methods)
        }
    }
}
