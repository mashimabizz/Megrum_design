import Foundation
import MegrumCore

extension ProposalCreateFlow {
    func normalizeMeetupEnd() {
        meetupEndAt = ProposalMeetupEndDateResolver.adjustedEnd(
            startAt: meetupStartAt,
            currentEndAt: meetupEndAt
        )
    }

    func saveSelectedMeetupCandidate() {
        guard meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) else {
            return
        }
        meetupCandidateDrafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
    }

    func applyMeetupCandidate(
        _ draft: ProposalMeetupCandidateDraft,
        at index: Int,
        reanchorCalendar: Bool = true
    ) {
        selectedMeetupCandidateIndex = index
        meetupStartAt = draft.startAt
        meetupEndAt = draft.endAt
        meetupPlaceName = draft.placeName
        meetupLatitudeText = draft.latitudeText
        meetupLongitudeText = draft.longitudeText
        if reanchorCalendar {
            meetupCalendarAnchorDate = calendarAnchorDate(for: draft.startAt)
        }
        normalizeMeetupEnd()
    }

    func selectMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.indices.contains(index), index != selectedMeetupCandidateIndex else {
            return
        }
        saveSelectedMeetupCandidate()
        applyMeetupCandidate(meetupCandidateDrafts[index], at: index)
    }

    func openMeetupPlaceSheet(for index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        saveSelectedMeetupCandidate()
        let draft = meetupCandidateDrafts[index]
        applyMeetupCandidate(draft, at: index)
        meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: index, draft: draft)
    }

    func previousMeetupPlaceDraft(before index: Int) -> ProposalMeetupCandidateDraft? {
        ProposalMeetupPlaceDraftResolver.previousReusableDraft(
            before: index,
            in: displayMeetupCandidateDrafts
        )
    }

    func saveMeetupPlaceSheetDraft(_ draft: ProposalMeetupCandidateDraft, at index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        meetupCandidateDrafts[index] = draft
        applyMeetupCandidate(draft, at: index)
    }

    func addMeetupCandidate() {
        guard meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates else {
            return
        }
        saveSelectedMeetupCandidate()
        let start = meetupEndAt.addingTimeInterval(30 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
        meetupCandidateDrafts.append(draft)
        let newIndex = meetupCandidateDrafts.count - 1
        applyMeetupCandidate(draft, at: newIndex)
        meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: newIndex, draft: draft)
    }

    func removeMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        saveSelectedMeetupCandidate()
        meetupCandidateDrafts.remove(at: index)
        if meetupCandidateDrafts.isEmpty {
            selectedMeetupCandidateIndex = 0
            meetupPlaceName = ""
            meetupLatitudeText = ""
            meetupLongitudeText = ""
            meetupEndAt = meetupStartAt.addingTimeInterval(ProposalMeetupCandidateDraft.defaultDuration)
            meetupPlaceSheetRoute = nil
            return
        }
        guard let nextIndex = ProposalMeetupCandidateSelectionReducer.selectedIndexAfterRemoving(
            removedIndex: index,
            selectedIndex: selectedMeetupCandidateIndex,
            remainingCount: meetupCandidateDrafts.count
        ) else {
            return
        }
        applyMeetupCandidate(meetupCandidateDrafts[nextIndex], at: nextIndex)
    }

    func shiftMeetupWeek(_ direction: Int) {
        meetupCalendarAnchorDate = ProposalMeetupCalendarModel.shiftedAnchor(
            anchorDate: meetupCalendarAnchorDate,
            direction: direction
        )
    }

    func shiftMeetupMonth(_ direction: Int) {
        meetupCalendarAnchorDate = ProposalMeetupCalendarModel.shiftedMonthAnchor(
            anchorDate: meetupCalendarAnchorDate,
            direction: direction
        )
    }

    func selectMeetupCalendarDay(_ day: Date) {
        meetupCalendarAnchorDate = calendarAnchorDate(for: day)
    }

    func createMeetupCandidate(day: Date, startSlot: Int, endSlot: Int) {
        let draft = ProposalMeetupCandidateDraft(
            startAt: ProposalMeetupCalendarModel.date(for: day, slot: startSlot),
            endAt: ProposalMeetupCalendarModel.date(for: day, slot: endSlot)
        )
        saveSelectedMeetupCandidate()
        if meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates {
            meetupCandidateDrafts.append(draft)
            let newIndex = meetupCandidateDrafts.count - 1
            applyMeetupCandidate(draft, at: newIndex)
            meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: newIndex, draft: draft)
        } else if meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) {
            meetupCandidateDrafts[selectedMeetupCandidateIndex] = draft
            applyMeetupCandidate(draft, at: selectedMeetupCandidateIndex)
            meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: selectedMeetupCandidateIndex, draft: draft)
        }
    }

    func updateMeetupCandidate(index: Int, day: Date, startSlot: Int, endSlot: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        let updated = meetupCandidateDrafts[index].applyingCalendarRange(
            day: day,
            startSlot: startSlot,
            endSlot: endSlot
        )
        meetupCandidateDrafts[index] = updated
        if index == selectedMeetupCandidateIndex {
            applyMeetupCandidate(updated, at: index, reanchorCalendar: false)
        }
    }

    func calendarAnchorDate(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
