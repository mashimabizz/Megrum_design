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
    @State private var sheetState: SearchFilterSheetState

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
        _sheetState = State(initialValue: SearchFilterSheetState(draft: initialDraft))
    }

    private var hasSelectedGroup: Bool {
        sheetState.hasSelectedGroup
    }

    private var selectedGroup: OshiGroup? {
        guard let selectedGroupID = sheetState.draft.selectedGroupID else {
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
            limitingToGroupID: sheetState.draft.selectedGroupID,
            limit: 48
        )
    }

    private var selectedTagSummary: String {
        sheetState.selectedTagSummary
    }

    var body: some View {
        Form {
            SearchOfferedGoodsFilterSection(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                characters: hasSelectedGroup ? appState.oshiCharacters : [],
                goodsTypes: appState.goodsTypes,
                selectedTagSummary: selectedTagSummary,
                selectedGroupID: $sheetState.draft.selectedGroupID,
                selectedMemberID: $sheetState.draft.selectedMemberID,
                selectedGoodsTypeID: $sheetState.draft.selectedGoodsTypeID,
                isLoadingGroups: appState.isLoadingOshiGroups,
                isLoadingMembers: appState.isLoadingOshiCharacters,
                isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
                onSelectGroup: selectGroup,
                onClearGroup: clearGroupSelection,
                onOpenTagPicker: {
                    sheetState.showTagPicker()
                }
            )

            SearchConditionMatchFilterSection(filters: $sheetState.draft.conditionMatches)

            SearchExchangeConditionFilterSection(
                selectedExchangeMethod: $sheetState.draft.selectedExchangeMethod,
                selectedPrefecture: $sheetState.draft.selectedMeetupPrefecture,
                placeMemo: $sheetState.draft.meetupPlaceMemo,
                selectedDates: $sheetState.draft.selectedMeetupDates,
                dateDraft: $sheetState.draft.meetupDateDraft,
                isDatePickerExpanded: $sheetState.isMeetupDatePickerExpanded,
                shippingFee: $sheetState.draft.shippingFee,
                shippingWindow: $sheetState.draft.shippingWindow,
                allowsOutOfConditionProposal: $sheetState.draft.allowsOutOfConditionProposal,
                isLocked: sheetState.draft.conditionMatches.matchesExchangeCondition,
                onAddDate: addMeetupDate,
                onRemoveDate: removeMeetupDate
            )

            SearchPaymentMethodFilterSection(
                selectedMethods: $sheetState.draft.selectedPaymentMethods,
                isLocked: sheetState.draft.conditionMatches.matchesPaymentCondition
            )

            SearchFilterResetSection(onReset: resetDraft)
        }
        .navigationTitle("検索フィルター")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("リセット", action: resetDraft)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            SearchFilterApplyFooter(action: applyAndDismiss)
        }
        .sheet(isPresented: $sheetState.isShowingTagPicker) {
            NavigationStack {
                SearchGoodsTagSelectionSheet(
                    candidateNames: availableGoodsTagNames,
                    selectedGroupName: selectedGroup?.name,
                    selectedTags: $sheetState.draft.selectedGoodsTagNames
                )
            }
        }
        .onChange(of: sheetState.draft.conditionMatches) { previous, current in
            applyDefaultConditions(previous: previous, current: current)
        }
    }

    private func addMeetupDate(_ date: Date) {
        sheetState.addMeetupDate(date)
    }

    private func removeMeetupDate(_ date: Date) {
        sheetState.removeMeetupDate(date)
    }

    private func selectGroup(_ group: OshiGroup) {
        sheetState.selectGroup(group)
        Task {
            await appState.loadOshiCharacters(group: group)
        }
    }

    private func clearGroupSelection() {
        sheetState.clearGroupSelection()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }

    private func resetDraft() {
        sheetState.resetDraft()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }

    private func applyAndDismiss() {
        onApply(sheetState.draft)
        dismiss()
    }

    private func applyDefaultConditions(
        previous: SearchConditionMatchFilters,
        current: SearchConditionMatchFilters
    ) {
        sheetState.applyDefaultConditions(
            previous: previous,
            current: current,
            defaultExchangeSettings: defaultExchangeSettings,
            defaultPaymentMethods: defaultPaymentMethods,
            viewer: appState.viewer
        )
    }
}

private struct SearchFilterApplyFooter: View {
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performButtonTap(action)
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
}
