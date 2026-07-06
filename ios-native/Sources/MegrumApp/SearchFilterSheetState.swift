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
        if draft.selectedGroupIDs.contains(group.id) {
            draft.selectedGroupIDs.remove(group.id)
        } else {
            draft.selectedGroupIDs.insert(group.id)
        }
        draft.selectedMemberIDs = []
    }

    mutating func clearGroupSelection() {
        draft.selectedGroupIDs = []
        draft.selectedMemberIDs = []
    }

    mutating func resetDraft() {
        draft = draft.reset()
    }

}
