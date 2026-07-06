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
            SearchGoodsConditionMultiSection(
                appState: appState,
                selectedGroupIDs: $sheetState.draft.selectedGroupIDs,
                selectedMemberIDs: $sheetState.draft.selectedMemberIDs,
                selectedGoodsTypeIDs: $sheetState.draft.selectedGoodsTypeIDs,
                selectedTagSummary: selectedTagSummary,
                onOpenTagPicker: {
                    sheetState.showTagPicker()
                }
            )

            Section {
                Toggle("あなたのグッズを求めている相手だけ", isOn: $sheetState.draft.wantsMyGoodsOnly)
                Toggle("定価交換OKの相手だけ", isOn: $sheetState.draft.wantsCashOK)
            } header: {
                Label("需要マッチ", systemImage: "flame")
            } footer: {
                Text("個別募集であなたのグッズを求めている相手や、定価交換の選択肢がある相手に絞り込みます。")
            }

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
                isLocked: false,
                onAddDate: addMeetupDate,
                onRemoveDate: removeMeetupDate
            )

            SearchPaymentMethodFilterSection(
                selectedMethods: $sheetState.draft.selectedPaymentMethods,
                isLocked: false
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
    }

    private func addMeetupDate(_ date: Date) {
        sheetState.addMeetupDate(date)
    }

    private func removeMeetupDate(_ date: Date) {
        sheetState.removeMeetupDate(date)
    }

    private func resetDraft() {
        sheetState.resetDraft()
        Task {
            await appState.loadOshiCharacters(group: nil)
        }
    }

    private func applyAndDismiss() {
        MegrumHaptics.buttonTap()
        onApply(sheetState.draft)
        dismiss()
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
