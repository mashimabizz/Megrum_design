import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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
