import Foundation
import MegrumCore

struct HomeExchangeSettingsDraftState: Equatable {
    var preference = HomeDefaultExchangeSettings.standard.preference
    var localPrefecture = ""
    var localDateKeys: Set<String> = []
    var localDateDetails: [String: HomeExchangeLocalDateDetail] = [:]
    var mailShippingFee = HomeDefaultExchangeSettings.standard.mailShippingFee
    var mailShippingDays = HomeDefaultExchangeSettings.standard.mailShippingDays
    var visibleMonth: Date
    var editingDate: HomeExchangeEditingDate?
    private(set) var didLoadDraft = false
    private(set) var hasUserEditedDraft = false

    init(visibleMonth: Date = HomeExchangeCalendarMonthBuilder.monthStart(containing: Date())) {
        self.visibleMonth = visibleMonth
    }

    var currentSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preference: preference,
            localPrefecture: primaryLocalPrefecture,
            localDateKeys: Array(localDateKeys),
            localDateDetails: localDateDetails.filter { localDateKeys.contains($0.key) },
            mailShippingFee: mailShippingFee,
            mailShippingDays: mailShippingDays
        )
    }

    mutating func loadIfNeeded(
        storedPreferenceRawValue: String,
        storedLocalPrefecture: String,
        storedLocalDateKeysRawValue: String,
        storedLocalDateDetailsRawValue: String,
        storedMailShippingFeeRawValue: String,
        storedMailShippingDaysRawValue: String,
        isListingReflectedDate: (String) -> Bool,
        now: Date = Date()
    ) {
        guard !didLoadDraft else {
            return
        }
        didLoadDraft = true
        preference = HomeExchangePreference(rawValue: storedPreferenceRawValue) ?? HomeDefaultExchangeSettings.standard.preference
        localPrefecture = storedLocalPrefecture
        localDateKeys = Set(HomeExchangeDateKey.normalizedKeys(from: storedLocalDateKeysRawValue))
        localDateDetails = HomeExchangeLocalDateDetailCodec.decode(storedLocalDateDetailsRawValue)
        mailShippingFee = IndividualListingShippingFeeDraft(rawValue: storedMailShippingFeeRawValue) ?? HomeDefaultExchangeSettings.standard.mailShippingFee
        mailShippingDays = IndividualListingShippingDaysDraft(rawValue: storedMailShippingDaysRawValue) ?? HomeDefaultExchangeSettings.standard.mailShippingDays
        discardUnsetDraftDateDetails(Array(localDateKeys), isListingReflectedDate: isListingReflectedDate)

        if let firstSelectedDate = localDateKeys.sorted().compactMap({ HomeExchangeDateKey.date(from: $0) }).first {
            visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: firstSelectedDate)
        } else {
            visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: now)
        }
    }

    mutating func selectPreference(_ selectedPreference: HomeExchangePreference) {
        hasUserEditedDraft = true
        preference = selectedPreference
    }

    mutating func applyRemoteSettingsIfPossible(_ settings: HomeDefaultExchangeSettings?) -> Bool {
        guard let settings, !hasUserEditedDraft else {
            return false
        }
        preference = settings.preference
        localPrefecture = settings.localPrefecture
        localDateKeys = Set(settings.localDateKeys)
        localDateDetails = settings.localDateDetails
        mailShippingFee = settings.mailShippingFee
        mailShippingDays = settings.mailShippingDays
        return true
    }

    mutating func markSaveSucceeded() {
        hasUserEditedDraft = false
    }

    func displayedLocalDateKeys(reflectedDetails: [String: HomeExchangeLocalDateDetail]) -> Set<String> {
        localDateKeys.union(reflectedDetails.keys)
    }

    func displayedLocalDateDetails(
        reflectedDetails: [String: HomeExchangeLocalDateDetail]
    ) -> [String: HomeExchangeLocalDateDetail] {
        localDateDetails.merging(reflectedDetails) { _, reflected in
            reflected
        }
    }

    mutating func tapDate(
        _ day: HomeExchangeCalendarDay,
        isListingReflectedDate: (String) -> Bool
    ) {
        hasUserEditedDraft = true
        if !isListingReflectedDate(day.key) {
            selectDate(day.key)
        }
        editingDate = HomeExchangeEditingDate(dateKeys: [day.key])
    }

    mutating func finishDragSelection(
        _ days: [HomeExchangeCalendarDay],
        isListingReflectedDate: (String) -> Bool
    ) {
        let keys = HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: days.map(\.key)))
        guard !keys.isEmpty else {
            return
        }
        hasUserEditedDraft = true
        for key in keys where !isListingReflectedDate(key) {
            selectDate(key)
        }
        let editableKeys = keys.filter { !isListingReflectedDate($0) }
        editingDate = HomeExchangeEditingDate(dateKeys: editableKeys.isEmpty ? keys : editableKeys)
    }

    mutating func saveDateDetail(
        _ keys: [String],
        detail: HomeExchangeLocalDateDetail,
        isListingReflectedDate: (String) -> Bool
    ) {
        hasUserEditedDraft = true
        guard detail.prefecture.nilIfBlank != nil else {
            removeDateDetail(keys, isListingReflectedDate: isListingReflectedDate)
            return
        }
        keys.forEach { key in
            localDateKeys.insert(key)
            localDateDetails[key] = detail
        }
    }

    mutating func removeDateDetail(
        _ keys: [String],
        isListingReflectedDate: (String) -> Bool
    ) {
        hasUserEditedDraft = true
        keys.forEach { key in
            guard !isListingReflectedDate(key) else {
                return
            }
            localDateKeys.remove(key)
            localDateDetails.removeValue(forKey: key)
        }
    }

    mutating func discardUnsetDraftDateDetails(
        _ keys: [String],
        isListingReflectedDate: (String) -> Bool
    ) {
        keys.forEach { key in
            guard !isListingReflectedDate(key),
                  localDateDetails[key]?.prefecture.nilIfBlank == nil
            else {
                return
            }
            localDateKeys.remove(key)
            localDateDetails.removeValue(forKey: key)
        }
    }

    private var primaryLocalPrefecture: String {
        localPrefecture.nilIfBlank
            ?? localDateKeys.sorted().compactMap { localDateDetails[$0]?.prefecture.nilIfBlank }.first
            ?? ""
    }

    private mutating func selectDate(_ key: String) {
        localDateKeys.insert(key)
        if localDateDetails[key] == nil {
            localDateDetails[key] = HomeExchangeLocalDateDetail(prefecture: "", memo: "")
        }
    }
}
