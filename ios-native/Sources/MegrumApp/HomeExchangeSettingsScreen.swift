import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsScreen: View {
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var storedPreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) private var storedLocalPrefecture = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) private var storedLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateDetails) private var storedLocalDateDetailsRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) private var storedMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) private var storedMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.configuredAt) private var configuredAt = 0.0
    @Environment(\.dismiss) private var dismiss

    var individualListings: [IndividualListing] = []

    @State private var draftPreference = HomeDefaultExchangeSettings.standard.preference
    @State private var draftLocalPrefecture = ""
    @State private var draftLocalDateKeys: Set<String> = []
    @State private var draftLocalDateDetails: [String: HomeExchangeLocalDateDetail] = [:]
    @State private var draftMailShippingFee = HomeDefaultExchangeSettings.standard.mailShippingFee
    @State private var draftMailShippingDays = HomeDefaultExchangeSettings.standard.mailShippingDays
    @State private var visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: Date())
    @State private var editingDate: HomeExchangeEditingDate?
    @State private var didLoadDraft = false

    var body: some View {
        HomeExchangeSettingsContent(
            draftPreference: $draftPreference,
            draftLocalPrefecture: $draftLocalPrefecture,
            draftMailShippingFee: $draftMailShippingFee,
            draftMailShippingDays: $draftMailShippingDays,
            visibleMonth: $visibleMonth,
            selectedDateKeys: displayedLocalDateKeys,
            dateDetails: displayedLocalDateDetails,
            onClose: dismiss.callAsFunction,
            onSelectPreference: selectPreference,
            onTapDay: tapDate,
            onFinishDragSelection: finishDragSelection
        )
        .safeAreaInset(edge: .bottom) {
            HomeExchangeSettingsSaveFooter(action: save)
        }
        .sheet(item: $editingDate) { editingDate in
            HomeExchangeLocalDateDetailSheet(
                dateKeys: editingDate.dateKeys,
                initialDetail: initialDetail(for: editingDate.dateKeys),
                isReadOnly: containsListingReflectedDate(editingDate.dateKeys),
                onSave: saveDateDetail,
                onRemove: removeDateDetail,
                onCancel: discardUnsetDraftDateDetails
            )
        }
        .homeExchangeSettingsNavigationBarHidden()
        .onAppear(perform: loadDraftIfNeeded)
    }

    private func loadDraftIfNeeded() {
        guard !didLoadDraft else {
            return
        }
        didLoadDraft = true
        draftPreference = HomeExchangePreference(rawValue: storedPreferenceRawValue) ?? HomeDefaultExchangeSettings.standard.preference
        draftLocalPrefecture = storedLocalPrefecture
        draftLocalDateKeys = Set(HomeExchangeDateKey.normalizedKeys(from: storedLocalDateKeysRawValue))
        draftLocalDateDetails = HomeExchangeLocalDateDetailCodec.decode(storedLocalDateDetailsRawValue)
        draftMailShippingFee = IndividualListingShippingFeeDraft(rawValue: storedMailShippingFeeRawValue) ?? HomeDefaultExchangeSettings.standard.mailShippingFee
        draftMailShippingDays = IndividualListingShippingDaysDraft(rawValue: storedMailShippingDaysRawValue) ?? HomeDefaultExchangeSettings.standard.mailShippingDays
        discardUnsetDraftDateDetails(Array(draftLocalDateKeys))

        if let firstSelectedDate = draftLocalDateKeys.sorted().compactMap({ HomeExchangeDateKey.date(from: $0) }).first {
            visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: firstSelectedDate)
        } else {
            visibleMonth = HomeExchangeCalendarMonthBuilder.monthStart(containing: Date())
        }
    }

    private func selectPreference(_ preference: HomeExchangePreference) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            draftPreference = preference
        }
    }

    private func save() {
        storedPreferenceRawValue = draftPreference.rawValue
        storedLocalPrefecture = primaryLocalPrefecture
        storedLocalDateKeysRawValue = HomeExchangeDateKey.rawValue(from: draftLocalDateKeys)
        storedLocalDateDetailsRawValue = HomeExchangeLocalDateDetailCodec.encode(
            draftLocalDateDetails.filter { draftLocalDateKeys.contains($0.key) }
        )
        storedMailShippingFeeRawValue = draftMailShippingFee.rawValue
        storedMailShippingDaysRawValue = draftMailShippingDays.rawValue
        configuredAt = Date().timeIntervalSince1970
        dismiss()
    }

    private var primaryLocalPrefecture: String {
        draftLocalPrefecture.nilIfBlank
            ?? draftLocalDateKeys.sorted().compactMap { draftLocalDateDetails[$0]?.prefecture.nilIfBlank }.first
            ?? ""
    }

    private var reflectedListingDateDetails: [String: HomeExchangeLocalDateDetail] {
        HomeExchangeListingConditionReflector.reflectedDetails(from: individualListings)
    }

    private var displayedLocalDateKeys: Set<String> {
        draftLocalDateKeys.union(reflectedListingDateDetails.keys)
    }

    private var displayedLocalDateDetails: [String: HomeExchangeLocalDateDetail] {
        draftLocalDateDetails.merging(reflectedListingDateDetails) { _, reflected in
            reflected
        }
    }

    private func tapDate(_ day: HomeExchangeCalendarDay) {
        if !isListingReflectedDate(day.key) {
            selectDate(day.key)
        }
        editingDate = HomeExchangeEditingDate(dateKeys: [day.key])
    }

    private func finishDragSelection(_ days: [HomeExchangeCalendarDay]) {
        let keys = HomeExchangeDateKey.normalizedKeys(from: HomeExchangeDateKey.rawValue(from: days.map(\.key)))
        guard !keys.isEmpty else {
            return
        }
        keys
            .filter { !isListingReflectedDate($0) }
            .forEach(selectDate)
        let editableKeys = keys.filter { !isListingReflectedDate($0) }
        editingDate = HomeExchangeEditingDate(dateKeys: editableKeys.isEmpty ? keys : editableKeys)
    }

    private func selectDate(_ key: String) {
        draftLocalDateKeys.insert(key)
        if draftLocalDateDetails[key] == nil {
            draftLocalDateDetails[key] = HomeExchangeLocalDateDetail(prefecture: "", memo: "")
        }
    }

    private func saveDateDetail(_ keys: [String], detail: HomeExchangeLocalDateDetail) {
        guard detail.prefecture.nilIfBlank != nil else {
            removeDateDetail(keys)
            return
        }
        keys.forEach { key in
            draftLocalDateKeys.insert(key)
            draftLocalDateDetails[key] = detail
        }
    }

    private func removeDateDetail(_ keys: [String]) {
        keys.forEach { key in
            guard !isListingReflectedDate(key) else {
                return
            }
            draftLocalDateKeys.remove(key)
            draftLocalDateDetails.removeValue(forKey: key)
        }
    }

    private func discardUnsetDraftDateDetails(_ keys: [String]) {
        keys.forEach { key in
            guard !isListingReflectedDate(key),
                  draftLocalDateDetails[key]?.prefecture.nilIfBlank == nil
            else {
                return
            }
            draftLocalDateKeys.remove(key)
            draftLocalDateDetails.removeValue(forKey: key)
        }
    }

    private func initialDetail(for keys: [String]) -> HomeExchangeLocalDateDetail {
        let details = keys.compactMap { displayedLocalDateDetails[$0] }
        let prefectures = Set(details.compactMap { $0.prefecture.nilIfBlank })
        let memos = Set(details.compactMap { $0.memo.nilIfBlank })
        return HomeExchangeLocalDateDetail(
            prefecture: prefectures.count == 1 ? prefectures.first ?? "" : "",
            memo: containsListingReflectedDate(keys) && memos.count > 1
                ? HomeExchangeListingConditionReflector.multipleMemoText
                : memos.count == 1 ? memos.first ?? "" : ""
        )
    }

    private func isListingReflectedDate(_ key: String) -> Bool {
        reflectedListingDateDetails[key] != nil
    }

    private func containsListingReflectedDate(_ keys: [String]) -> Bool {
        keys.contains(where: isListingReflectedDate)
    }
}
