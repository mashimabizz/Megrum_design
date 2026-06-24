import Foundation
import SwiftUI

enum ProposalMeetupCalendarLayoutBuilder {
    static func renderedCandidateBlocks(
        drafts: [ProposalMeetupCandidateDraft],
        selectedIndex: Int,
        candidateEdit: ProposalMeetupCalendarCandidateEdit?,
        days: [Date],
        dayWidth: CGFloat,
        calendar: Calendar
    ) -> [ProposalMeetupCalendarRenderedCandidateBlock] {
        drafts.enumerated().compactMap { index, draft in
            let renderedDraft = renderedCandidateDraft(
                draft,
                index: index,
                candidateEdit: candidateEdit,
                days: days,
                calendar: calendar
            )
            guard let layout = candidateLayout(
                for: renderedDraft,
                days: days,
                dayWidth: dayWidth,
                calendar: calendar
            ) else {
                return nil
            }
            return ProposalMeetupCalendarRenderedCandidateBlock(
                draft: renderedDraft,
                index: index,
                isSelected: index == selectedIndex,
                x: layout.x,
                y: layout.y,
                width: layout.width,
                height: layout.height
            )
        }
    }

    static func selectedDayIndex(
        drafts: [ProposalMeetupCandidateDraft],
        selectedIndex: Int,
        anchorDate: Date,
        calendar: Calendar
    ) -> Int {
        let days = ProposalMeetupCalendarModel.visibleDays(anchorDate: anchorDate, calendar: calendar)
        guard drafts.indices.contains(selectedIndex) else {
            return 0
        }
        let selectedDay = calendar.startOfDay(for: drafts[selectedIndex].startAt)
        return days.firstIndex(where: { calendar.isDate($0, inSameDayAs: selectedDay) }) ?? 0
    }

    static func candidateIndex(
        at location: CGPoint,
        drafts: [ProposalMeetupCandidateDraft],
        candidateEdit: ProposalMeetupCalendarCandidateEdit?,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat,
        calendar: Calendar
    ) -> Int? {
        let gridLocation = ProposalMeetupCalendarModel.weekGridPoint(
            from: location,
            containerWidth: containerWidth,
            dayWidth: dayWidth
        )
        for (index, draft) in drafts.enumerated().reversed() {
            let renderedDraft = renderedCandidateDraft(
                draft,
                index: index,
                candidateEdit: candidateEdit,
                days: days,
                calendar: calendar
            )
            guard let layout = candidateLayout(
                for: renderedDraft,
                days: days,
                dayWidth: dayWidth,
                calendar: calendar
            ) else {
                continue
            }
            let rect = CGRect(x: layout.x, y: layout.y, width: layout.width, height: layout.height)
                .insetBy(dx: -6, dy: -ProposalMeetupCalendarModel.slotHeight)
            if rect.contains(gridLocation) {
                return index
            }
        }
        return nil
    }

    static func currentCandidateEdit(
        index: Int,
        drafts: [ProposalMeetupCandidateDraft],
        days: [Date],
        calendar: Calendar
    ) -> ProposalMeetupCalendarCandidateEdit {
        let draft = drafts[index]
        let day = calendar.startOfDay(for: draft.startAt)
        let dayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) ?? 0
        let startSlot = ProposalMeetupCalendarModel.slotIndex(for: draft.startAt, calendar: calendar)
        let endSlot = max(startSlot + 1, ProposalMeetupCalendarModel.slotIndex(for: draft.endAt, calendar: calendar))
        return ProposalMeetupCalendarCandidateEdit(index: index, dayIndex: dayIndex, startSlot: startSlot, endSlot: endSlot)
    }

    private static func renderedCandidateDraft(
        _ draft: ProposalMeetupCandidateDraft,
        index: Int,
        candidateEdit: ProposalMeetupCalendarCandidateEdit?,
        days: [Date],
        calendar: Calendar
    ) -> ProposalMeetupCandidateDraft {
        guard let candidateEdit,
              candidateEdit.index == index,
              days.indices.contains(candidateEdit.dayIndex)
        else {
            return draft
        }
        return draft.applyingCalendarRange(
            day: days[candidateEdit.dayIndex],
            startSlot: candidateEdit.startSlot,
            endSlot: candidateEdit.endSlot,
            calendar: calendar
        )
    }

    private static func candidateLayout(
        for draft: ProposalMeetupCandidateDraft,
        days: [Date],
        dayWidth: CGFloat,
        calendar: Calendar
    ) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)? {
        let day = calendar.startOfDay(for: draft.startAt)
        guard let dayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) else {
            return nil
        }
        let startSlot = ProposalMeetupCalendarModel.slotIndex(for: draft.startAt, calendar: calendar)
        let endSlot = max(startSlot + 1, ProposalMeetupCalendarModel.slotIndex(for: draft.endAt, calendar: calendar))
        let height = CGFloat(endSlot - startSlot) * ProposalMeetupCalendarModel.slotHeight - 4
        return (
            x: ProposalMeetupCalendarModel.timeLabelWidth + CGFloat(dayIndex) * (dayWidth + ProposalMeetupCalendarModel.daySpacing) + 4,
            y: CGFloat(startSlot) * ProposalMeetupCalendarModel.slotHeight + 2,
            width: dayWidth - 8,
            height: max(20, height)
        )
    }
}
