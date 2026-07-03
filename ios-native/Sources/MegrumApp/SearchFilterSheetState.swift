import Foundation
import MegrumCore

struct SearchFilterSheetState: Equatable {
    var draft: SearchFilterDraft
    var isMeetupDatePickerExpanded = false
    var isShowingTagPicker = false

    init(draft: SearchFilterDraft) {
        self.draft = draft
    }

    var hasSelectedGroup: Bool {
        draft.selectedGroupID != nil
    }

    var selectedTagSummary: String {
        if draft.selectedGoodsTagNames.isEmpty {
            return "選択する"
        }
        return "\(draft.selectedGoodsTagNames.count)件"
    }

    mutating func showTagPicker() {
        isShowingTagPicker = true
    }

    mutating func addMeetupDate(_ date: Date, calendar: Calendar = .current) {
        let normalizedDate = calendar.startOfDay(for: date)
        guard !draft.selectedMeetupDates.contains(normalizedDate) else {
            return
        }
        draft.selectedMeetupDates.append(normalizedDate)
        draft.selectedMeetupDates.sort()
    }

    mutating func removeMeetupDate(_ date: Date, calendar: Calendar = .current) {
        let normalizedDate = calendar.startOfDay(for: date)
        draft.selectedMeetupDates.removeAll { calendar.isDate($0, inSameDayAs: normalizedDate) }
    }

    mutating func selectGroup(_ group: OshiGroup) {
        draft.selectedGroupID = group.id
        draft.selectedMemberID = nil
    }

    mutating func clearGroupSelection() {
        draft.selectedGroupID = nil
        draft.selectedMemberID = nil
    }

    mutating func resetDraft() {
        draft = draft.reset()
    }

    mutating func applyDefaultConditions(
        previous: SearchConditionMatchFilters,
        current: SearchConditionMatchFilters,
        defaultExchangeSettings: HomeDefaultExchangeSettings,
        defaultPaymentMethods: [UserPaymentMethod],
        viewer: UserProfile?
    ) {
        if current.matchesExchangeCondition, !previous.matchesExchangeCondition {
            draft.applyDefaultExchangeCondition(
                settings: defaultExchangeSettings,
                viewer: viewer
            )
        }
        if current.matchesPaymentCondition, !previous.matchesPaymentCondition {
            draft.applyDefaultPaymentCondition(methods: defaultPaymentMethods)
        }
    }
}
