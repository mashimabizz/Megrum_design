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
        ZStack {
            HomeExchangeSettingsBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HomeExchangeSettingsHeader(onClose: dismiss.callAsFunction)

                    HomeExchangePreferenceCardPicker(
                        selection: $draftPreference,
                        onSelect: selectPreference
                    )

                    if draftPreference.acceptsMail {
                        HomeExchangeMailConditionsCard(
                            shippingFee: $draftMailShippingFee,
                            shippingDays: $draftMailShippingDays
                        )
                    }

                    if draftPreference.acceptsLocal {
                        Text("現地交換可能な場所と日程")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                            .padding(.horizontal, 8)

                        HomeExchangeSettingsCalendarCard(
                            visibleMonth: $visibleMonth,
                            selectedPrefecture: $draftLocalPrefecture,
                            selectedDateKeys: displayedLocalDateKeys,
                            dateDetails: displayedLocalDateDetails,
                            onTapDay: tapDate,
                            onFinishDragSelection: finishDragSelection
                        )

                        HomeExchangeSettingsInstructionBanner()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
        }
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

private struct HomeExchangeSettingsBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                MegrumTheme.canvas,
                MegrumTheme.lavender.opacity(0.12),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct HomeExchangeSettingsHeader: View {
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Text("交換条件")
                .font(.title2.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity)

            HStack {
                Button("閉じる", action: onClose)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 17)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 16, y: 8)

                Spacer(minLength: 0)
            }
        }
    }
}

private struct HomeExchangePreferenceCardPicker: View {
    @Binding var selection: HomeExchangePreference
    var onSelect: (HomeExchangePreference) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(HomeExchangePreference.allCases) { preference in
                HomeExchangePreferenceCard(
                    preference: preference,
                    isSelected: selection == preference
                ) {
                    onSelect(preference)
                }
            }
        }
    }
}

private struct HomeExchangePreferenceCard: View {
    var preference: HomeExchangePreference
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 7) {
                    Image(systemName: preference.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(preference.iconTint)
                        .frame(width: 32, height: 32)
                        .background(preference.iconTint.opacity(0.13), in: Circle())
                        .accessibilityHidden(true)

                    Text(preference.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.62))

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                isSelected ? Color.white.opacity(0.82) : Color.white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.7 : 1
                    )
            }
            .shadow(color: MegrumTheme.ink.opacity(isSelected ? 0.08 : 0.035), radius: isSelected ? 18 : 10, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preference.displayName)、\(isSelected ? "選択中" : "未選択")")
    }
}

private struct HomeExchangeMailConditionsCard: View {
    @Binding var shippingFee: IndividualListingShippingFeeDraft
    @Binding var shippingDays: IndividualListingShippingDaysDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("郵送交換の条件")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 8)

            VStack(spacing: 14) {
                HomeExchangeMailConditionSegmentRow(
                    title: "送料の負担",
                    selection: $shippingFee,
                    values: IndividualListingShippingFeeDraft.selectableCases
                )
                Divider().overlay(MegrumTheme.ink.opacity(0.08))
                HomeExchangeMailConditionSegmentRow(
                    title: "発送目安",
                    selection: $shippingDays,
                    values: IndividualListingShippingDaysDraft.allCases
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.lavender.opacity(0.09), radius: 18, y: 10)
        }
    }
}

private struct HomeExchangeMailConditionSegmentRow<Value: Identifiable & Equatable>: View where Value.ID == String {
    var title: String
    @Binding var selection: Value
    var values: [Value]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)

            HStack(spacing: 7) {
                ForEach(values) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(segmentTitle(for: value))
                            .font(.caption.weight(.black))
                            .foregroundStyle(selection == value ? .white : MegrumTheme.ink.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selection == value ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.05),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }
        }
    }

    private func segmentTitle(for value: Value) -> String {
        if let shippingFee = value as? IndividualListingShippingFeeDraft {
            return shippingFee.title
        }
        if let shippingDays = value as? IndividualListingShippingDaysDraft {
            return shippingDays.title
        }
        return value.id
    }
}

private struct HomeExchangeSettingsInstructionBanner: View {
    var body: some View {
        Label {
            Text("日付タップで場所とメモ、横ドラッグで複数日程を追加できます")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "hand.tap.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct HomeExchangeSettingsSaveFooter: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("保存")
                .font(.title3.weight(.black))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.lavender.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}

private extension HomeExchangePreference {
    var iconName: String {
        switch self {
        case .local:
            "mappin.circle.fill"
        case .mail:
            "shippingbox.fill"
        case .both:
            "arrow.left.arrow.right.circle.fill"
        }
    }

    var iconTint: Color {
        switch self {
        case .local:
            MegrumTheme.lavender
        case .mail:
            MegrumTheme.pink
        case .both:
            MegrumTheme.lavender.opacity(0.82)
        }
    }
}

private extension View {
    @ViewBuilder
    func homeExchangeSettingsNavigationBarHidden() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
