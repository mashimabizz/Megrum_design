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
    @Environment(\.megrumSlidePresentationDismiss) private var slideDismiss

    @ObservedObject var appState: MegrumAppState
    var individualListings: [IndividualListing] = []
    var onClose: (() -> Void)?

    @State private var draftState = HomeExchangeSettingsDraftState()

    var body: some View {
        HomeExchangeSettingsContent(
            draftPreference: $draftState.preference,
            draftLocalPrefecture: $draftState.localPrefecture,
            draftMailShippingFee: $draftState.mailShippingFee,
            draftMailShippingDays: $draftState.mailShippingDays,
            visibleMonth: $draftState.visibleMonth,
            selectedDateKeys: displayedLocalDateKeys,
            dateDetails: displayedLocalDateDetails,
            onClose: closeScreen,
            onSelectPreference: selectPreference,
            onTapDay: tapDate,
            onFinishDragSelection: finishDragSelection
        )
        .safeAreaInset(edge: .bottom) {
            HomeExchangeSettingsSaveFooter(
                isSaving: appState.isSavingExchangeSettings,
                action: save
            )
        }
        .sheet(item: $draftState.editingDate) { editingDate in
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
        .task {
            await appState.loadExchangeSettings()
        }
        .onChange(of: appState.exchangeSettings) { _, settings in
            applyRemoteSettingsIfPossible(settings)
        }
    }

    private func loadDraftIfNeeded() {
        draftState.loadIfNeeded(
            storedPreferenceRawValue: storedPreferenceRawValue,
            storedLocalPrefecture: storedLocalPrefecture,
            storedLocalDateKeysRawValue: storedLocalDateKeysRawValue,
            storedLocalDateDetailsRawValue: storedLocalDateDetailsRawValue,
            storedMailShippingFeeRawValue: storedMailShippingFeeRawValue,
            storedMailShippingDaysRawValue: storedMailShippingDaysRawValue,
            isListingReflectedDate: isListingReflectedDate
        )
    }

    private func selectPreference(_ preference: HomeExchangePreference) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            draftState.selectPreference(preference)
        }
    }

    private func save() {
        let settings = draftState.currentSettings
        persistLocally(settings)
        Task {
            if await appState.saveExchangeSettings(settings) {
                draftState.markSaveSucceeded()
                closeScreen()
            }
        }
    }

    private func persistLocally(_ settings: HomeDefaultExchangeSettings) {
        storedPreferenceRawValue = settings.preference.rawValue
        storedLocalPrefecture = settings.localPrefecture
        storedLocalDateKeysRawValue = HomeExchangeDateKey.rawValue(from: settings.localDateKeys)
        storedLocalDateDetailsRawValue = HomeExchangeLocalDateDetailCodec.encode(settings.localDateDetails)
        storedMailShippingFeeRawValue = settings.mailShippingFee.rawValue
        storedMailShippingDaysRawValue = settings.mailShippingDays.rawValue
        configuredAt = Date().timeIntervalSince1970
    }

    private func applyRemoteSettingsIfPossible(_ settings: HomeDefaultExchangeSettings?) {
        guard draftState.applyRemoteSettingsIfPossible(settings),
              let settings
        else {
            return
        }
        persistLocally(settings)
    }

    private func closeScreen() {
        if let onClose {
            onClose()
        } else if let slideDismiss {
            slideDismiss()
        } else {
            dismiss()
        }
    }

    private var reflectedListingDateDetails: [String: HomeExchangeLocalDateDetail] {
        HomeExchangeListingConditionReflector.reflectedDetails(from: individualListings)
    }

    private var displayedLocalDateKeys: Set<String> {
        draftState.displayedLocalDateKeys(reflectedDetails: reflectedListingDateDetails)
    }

    private var displayedLocalDateDetails: [String: HomeExchangeLocalDateDetail] {
        draftState.displayedLocalDateDetails(reflectedDetails: reflectedListingDateDetails)
    }

    private func tapDate(_ day: HomeExchangeCalendarDay) {
        draftState.tapDate(day, isListingReflectedDate: isListingReflectedDate)
    }

    private func finishDragSelection(_ days: [HomeExchangeCalendarDay]) {
        draftState.finishDragSelection(days, isListingReflectedDate: isListingReflectedDate)
    }

    private func saveDateDetail(_ keys: [String], detail: HomeExchangeLocalDateDetail) {
        draftState.saveDateDetail(keys, detail: detail, isListingReflectedDate: isListingReflectedDate)
    }

    private func removeDateDetail(_ keys: [String]) {
        draftState.removeDateDetail(keys, isListingReflectedDate: isListingReflectedDate)
    }

    private func discardUnsetDraftDateDetails(_ keys: [String]) {
        draftState.discardUnsetDraftDateDetails(keys, isListingReflectedDate: isListingReflectedDate)
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
