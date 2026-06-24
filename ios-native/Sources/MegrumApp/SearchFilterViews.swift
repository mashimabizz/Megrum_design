import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

private func searchFilterDateText(_ date: Date) -> String {
    date.formatted(
        .dateTime
            .locale(Locale(identifier: "ja_JP"))
            .month()
            .day()
            .weekday(.abbreviated)
    )
}

private let searchFilterJapanesePrefectures = [
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
    "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
    "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
    "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
    "鳥取県", "島根県", "岡山県", "広島県", "山口県",
    "徳島県", "香川県", "愛媛県", "高知県",
    "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
]

struct SearchFilterSheet: View {
    @ObservedObject var appState: MegrumAppState
    var defaultExchangeSettings: HomeDefaultExchangeSettings
    var defaultPaymentMethods: [UserPaymentMethod]
    var onApply: (SearchFilterDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: SearchFilterDraft
    @State private var isMeetupDatePickerExpanded = false
    @State private var isShowingTagPicker = false

    init(
        appState: MegrumAppState,
        initialDraft: SearchFilterDraft,
        defaultExchangeSettings: HomeDefaultExchangeSettings,
        defaultPaymentMethods: [UserPaymentMethod],
        onApply: @escaping (SearchFilterDraft) -> Void
    ) {
        self.appState = appState
        self.defaultExchangeSettings = defaultExchangeSettings
        self.defaultPaymentMethods = defaultPaymentMethods
        self.onApply = onApply
        _draft = State(initialValue: initialDraft)
    }

    private var hasSelectedGroup: Bool {
        draft.selectedGroupID != nil
    }

    private var selectedGroup: OshiGroup? {
        guard let selectedGroupID = draft.selectedGroupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == selectedGroupID }
    }

    private var availableGoodsTagNames: [String] {
        SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: appState.userOshiSelections,
            wishes: appState.wishes,
            inventory: appState.inventory,
            viewerID: appState.viewer?.id,
            limitingToGroupID: draft.selectedGroupID,
            limit: 48
        )
    }

    private var selectedTagSummary: String {
        if draft.selectedGoodsTagNames.isEmpty {
            return "選択する"
        }
        return "\(draft.selectedGoodsTagNames.count)件"
    }

    var body: some View {
        Form {
            SearchOfferedGoodsFilterSection(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                characters: hasSelectedGroup ? appState.oshiCharacters : [],
                goodsTypes: appState.goodsTypes,
                selectedTagSummary: selectedTagSummary,
                selectedGroupID: $draft.selectedGroupID,
                selectedMemberID: $draft.selectedMemberID,
                selectedGoodsTypeID: $draft.selectedGoodsTypeID,
                isLoadingGroups: appState.isLoadingOshiGroups,
                isLoadingMembers: appState.isLoadingOshiCharacters,
                isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
                onSelectGroup: selectGroup,
                onClearGroup: clearGroupSelection,
                onOpenTagPicker: {
                    isShowingTagPicker = true
                }
            )

            SearchConditionMatchFilterSection(filters: $draft.conditionMatches)

            SearchExchangeConditionFilterSection(
                selectedExchangeMethod: $draft.selectedExchangeMethod,
                selectedPrefecture: $draft.selectedMeetupPrefecture,
                placeMemo: $draft.meetupPlaceMemo,
                selectedDates: $draft.selectedMeetupDates,
                dateDraft: $draft.meetupDateDraft,
                isDatePickerExpanded: $isMeetupDatePickerExpanded,
                shippingFee: $draft.shippingFee,
                shippingWindow: $draft.shippingWindow,
                allowsOutOfConditionProposal: $draft.allowsOutOfConditionProposal,
                isLocked: draft.conditionMatches.matchesExchangeCondition,
                onAddDate: addMeetupDate,
                onRemoveDate: removeMeetupDate
            )

            SearchPaymentMethodFilterSection(
                selectedMethods: $draft.selectedPaymentMethods,
                isLocked: draft.conditionMatches.matchesPaymentCondition
            )

            SearchFilterResetSection(onReset: resetDraft)
        }
        .navigationTitle("検索フィルター")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("リセット") {
                    resetDraft()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onApply(draft)
                dismiss()
            } label: {
                Text("この条件で検索")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [MegrumTheme.lavender, MegrumTheme.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: MegrumTheme.lavender.opacity(0.25), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
        .sheet(isPresented: $isShowingTagPicker) {
            NavigationStack {
                SearchGoodsTagSelectionSheet(
                    candidateNames: availableGoodsTagNames,
                    selectedGroupName: selectedGroup?.name,
                    selectedTags: $draft.selectedGoodsTagNames
                )
            }
        }
        .onChange(of: draft.conditionMatches) { previous, current in
            if current.matchesExchangeCondition, !previous.matchesExchangeCondition {
                draft.applyDefaultExchangeCondition(
                    settings: defaultExchangeSettings,
                    viewer: appState.viewer
                )
            }
            if current.matchesPaymentCondition, !previous.matchesPaymentCondition {
                draft.applyDefaultPaymentCondition(methods: defaultPaymentMethods)
            }
        }
    }

    private func addMeetupDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard !draft.selectedMeetupDates.contains(normalizedDate) else {
            return
        }
        draft.selectedMeetupDates.append(normalizedDate)
        draft.selectedMeetupDates.sort()
    }

    private func removeMeetupDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        draft.selectedMeetupDates.removeAll { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
    }

    private func selectGroup(_ group: OshiGroup) {
        draft.selectedGroupID = group.id
        draft.selectedMemberID = nil
        Task {
            await appState.loadOshiCharacters(group: group)
        }
    }

    private func clearGroupSelection() {
        draft.selectedGroupID = nil
        draft.selectedMemberID = nil
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }

    private func resetDraft() {
        draft = draft.reset()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }
}

private struct SearchOfferedGoodsFilterSection: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var selectedTagSummary: String
    @Binding var selectedGroupID: UUID?
    @Binding var selectedMemberID: UUID?
    @Binding var selectedGoodsTypeID: UUID?
    var isLoadingGroups: Bool
    var isLoadingMembers: Bool
    var isLoadingGoodsTypes: Bool
    var onSelectGroup: (OshiGroup) -> Void
    var onClearGroup: () -> Void
    var onOpenTagPicker: () -> Void

    private var selectedGroupName: String {
        guard let selectedGroupID,
              let group = groups.first(where: { $0.id == selectedGroupID })
        else {
            return "すべて"
        }
        return group.name
    }

    var body: some View {
        Section {
            NavigationLink {
                SearchFilterOshiGroupPickerDestination(
                    genres: genres,
                    groups: groups,
                    selectedGroupIDs: selectedGroupID.map { Set([$0]) } ?? [],
                    onSelectGroup: onSelectGroup
                )
            } label: {
                HStack {
                    Text("グループ")
                    Spacer()
                    Text(selectedGroupName)
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
            }

            if selectedGroupID != nil {
                Button("グループをクリア", action: onClearGroup)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }

            if isLoadingGroups {
                ProgressView("グループを読み込み中")
            }

            Picker("メンバー", selection: $selectedMemberID) {
                Text(selectedGroupID == nil ? "グループ選択後" : "グループ全体").tag(Optional<UUID>.none)
                ForEach(characters) { character in
                    Text(character.name).tag(Optional(character.id))
                }
            }
            .disabled(selectedGroupID == nil)
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoadingMembers {
                ProgressView("メンバーを読み込み中")
            }

            Picker("グッズ種別", selection: $selectedGoodsTypeID) {
                Text("すべて").tag(Optional<UUID>.none)
                ForEach(goodsTypes) { goodsType in
                    Text(goodsType.name).tag(Optional(goodsType.id))
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            if isLoadingGoodsTypes {
                ProgressView("グッズ種別を読み込み中")
            }

            Button(action: onOpenTagPicker) {
                HStack {
                    Text("タグ")
                    Spacer()
                    Text(selectedTagSummary)
                        .foregroundStyle(MegrumTheme.muted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Label("相手が譲るグッズ", systemImage: "shippingbox")
        }
    }
}

private struct SearchFilterOshiGroupPickerDestination: View {
    var genres: [OshiGenre]
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var onSelectGroup: (OshiGroup) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OshiMasterSelectSheet(
            genres: genres,
            groups: groups,
            selectedGroupIDs: selectedGroupIDs,
            charactersByGroupID: [:],
            allowsMultipleSelection: false,
            onClose: { dismiss() },
            onRequest: { _ in dismiss() },
            onSelect: { group in
                onSelectGroup(group)
                dismiss()
            },
            onRegisterSelected: nil
        )
    }
}

private struct SearchConditionMatchFilterSection: View {
    @Binding var filters: SearchConditionMatchFilters

    var body: some View {
        Section {
            SearchConditionMatchToggleRow(
                title: "Wishに合う",
                subtitle: "グッズ○",
                isOn: $filters.matchesWish
            )
            SearchConditionMatchToggleRow(
                title: SearchFilterPresentation.individualListingMatchTitle,
                subtitle: "グッズ◎",
                isOn: $filters.matchesIndividualListing
            )
            SearchConditionMatchToggleRow(
                title: "交換条件が合う",
                subtitle: "自分の交換条件と重なるもの",
                isOn: $filters.matchesExchangeCondition
            )
            SearchConditionMatchToggleRow(
                title: "支払条件が合う",
                subtitle: "自分の支払い条件と重なるもの",
                isOn: $filters.matchesPaymentCondition
            )
        } header: {
            Label("条件マッチ", systemImage: "heart")
        }
    }
}

private struct SearchConditionMatchToggleRow: View {
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(title)
                Spacer(minLength: 12)
                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .tint(MegrumTheme.lavender)
    }
}

private struct SearchExchangeConditionFilterSection: View {
    @Binding var selectedExchangeMethod: ExchangeMethod?
    @Binding var selectedPrefecture: String
    @Binding var placeMemo: String
    @Binding var selectedDates: [Date]
    @Binding var dateDraft: Date
    @Binding var isDatePickerExpanded: Bool
    @Binding var shippingFee: String
    @Binding var shippingWindow: String
    @Binding var allowsOutOfConditionProposal: Bool
    var isLocked: Bool
    var onAddDate: (Date) -> Void
    var onRemoveDate: (Date) -> Void

    var body: some View {
        Section {
            Picker("交換手段", selection: $selectedExchangeMethod) {
                Text("指定なし").tag(Optional<ExchangeMethod>.none)
                ForEach(ExchangeMethod.allCases) { method in
                    Text(method.displayName).tag(Optional(method))
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Picker("都道府県", selection: $selectedPrefecture) {
                Text("指定なし").tag("")
                ForEach(searchFilterJapanesePrefectures, id: \.self) { prefecture in
                    Text(prefecture).tag(prefecture)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            TextField("場所メモ", text: $placeMemo)

            DisclosureGroup(isExpanded: $isDatePickerExpanded) {
                DatePicker("日程を追加", selection: $dateDraft, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Button("この日程を追加", systemImage: "calendar.badge.plus") {
                    onAddDate(dateDraft)
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))

                ForEach(selectedDates, id: \.self) { date in
                    HStack {
                        Text(searchFilterDateText(date))
                        Spacer()
                        Button {
                            onRemoveDate(date)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            } label: {
                HStack {
                    Text("日程")
                    Spacer()
                    Text(selectedDates.isEmpty ? "指定なし" : "\(selectedDates.count)件")
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Picker("送料", selection: $shippingFee) {
                Text("指定なし").tag("")
                ForEach(IndividualListingShippingFeeDraft.selectableCases) { option in
                    Text(option.title).tag(option.title)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Picker("発送目安", selection: $shippingWindow) {
                Text("指定なし").tag("")
                ForEach(IndividualListingShippingDaysDraft.allCases) { option in
                    Text(option.title).tag(option.title)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif

            Toggle("条件外打診", isOn: $allowsOutOfConditionProposal)
                .tint(MegrumTheme.lavender)
        } header: {
            Label("交換条件", systemImage: "mappin.circle")
        }
        .disabled(isLocked)
    }
}

private struct SearchPaymentMethodFilterSection: View {
    @Binding var selectedMethods: Set<UserPaymentMethod>
    var isLocked: Bool

    private let columns = [GridItem(.adaptive(minimum: 124), spacing: 10)]

    var body: some View {
        Section {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(UserPaymentMethod.allCases) { method in
                    SearchPaymentMethodChip(
                        method: method,
                        isSelected: selectedMethods.contains(method),
                        action: {
                            toggle(method)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("支払い条件", systemImage: "wallet.pass")
        }
        .disabled(isLocked)
    }

    private func toggle(_ method: UserPaymentMethod) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }
}

private struct SearchPaymentMethodChip: View {
    var method: UserPaymentMethod
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(method.displayName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            } icon: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : SearchFilterPresentation.paymentSymbol(for: method))
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .frame(maxWidth: .infinity)
            .background(isSelected ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.76), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? MegrumTheme.lavender.opacity(0.74) : MegrumTheme.muted.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SearchFilterResetSection: View {
    var onReset: () -> Void

    var body: some View {
        Section {
            Button("すべてリセット", role: .destructive) {
                onReset()
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
        }
    }
}
