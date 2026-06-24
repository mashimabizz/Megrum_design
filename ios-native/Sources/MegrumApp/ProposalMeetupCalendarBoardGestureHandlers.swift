import Foundation
import SwiftUI

extension ProposalMeetupCalendarWeekEditor {
    func handleBoardChanged(
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) {
        if boardTouchState == nil {
            let point = calendarPoint(
                from: value.startLocation,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            let touchedCandidateIndex = candidateIndex(
                at: value.startLocation,
                days: days,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            let originalEdit = touchedCandidateIndex.map { currentCandidateEdit(index: $0, days: days) }
            let pointerOffset = originalEdit.map {
                max(0, min($0.endSlot - $0.startSlot - 1, point.slot - $0.startSlot))
            }
            boardTouchState = ProposalMeetupCalendarBoardTouchState(
                startTime: Date(),
                startLocation: value.startLocation,
                dayIndex: point.dayIndex,
                startSlot: point.slot,
                mode: .pending,
                candidateIndex: touchedCandidateIndex,
                originalDayIndex: originalEdit?.dayIndex,
                originalStartSlot: originalEdit?.startSlot,
                originalEndSlot: originalEdit?.endSlot,
                pointerStartOffsetSlots: pointerOffset
            )
            scheduleBoardLongPress(dayIndex: point.dayIndex, startSlot: point.slot)
        }
        guard var state = boardTouchState else {
            return
        }
        let dx = value.location.x - state.startLocation.x
        let dy = value.location.y - state.startLocation.y
        if state.mode == .pending,
           state.candidateIndex == nil,
           abs(dx) > 10,
           abs(dx) > abs(dy) * 1.08 {
            cancelBoardLongPress()
            state.mode = .swiping
            boardTouchState = state
            weekDragOffset = ProposalMeetupCalendarModel.clampedWeekDragOffset(dx, containerWidth: dayWidth * CGFloat(ProposalMeetupCalendarModel.visibleDayCount))
            return
        }
        if state.mode == .swiping {
            weekDragOffset = ProposalMeetupCalendarModel.clampedWeekDragOffset(dx, containerWidth: dayWidth * CGFloat(ProposalMeetupCalendarModel.visibleDayCount))
            return
        }
        if state.mode == .pending,
           hypot(dx, dy) > ProposalMeetupCalendarModel.touchCancelDistance {
            if state.candidateIndex == nil {
                cancelBoardLongPress()
                state.mode = .creating
                boardTouchState = state
                let point = calendarPoint(
                    from: value.location,
                    dayWidth: dayWidth,
                    containerWidth: containerWidth
                )
                previewDraft = ProposalMeetupCalendarPreview(
                    dayIndex: point.dayIndex,
                    startSlot: state.startSlot,
                    currentSlot: point.slot
                )
                return
            } else {
                state.hasMovedBeyondTapTolerance = true
                boardTouchState = state
                return
            }
        }
        if state.mode == .creating {
            let point = calendarPoint(
                from: value.location,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            previewDraft = ProposalMeetupCalendarPreview(
                dayIndex: point.dayIndex,
                startSlot: state.startSlot,
                currentSlot: point.slot
            )
        }
        if state.mode == .movingCandidate,
           let candidateIndex = state.candidateIndex,
           let originalStartSlot = state.originalStartSlot,
           let originalEndSlot = state.originalEndSlot,
           let pointerStartOffsetSlots = state.pointerStartOffsetSlots {
            let point = calendarPoint(
                from: value.location,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            let duration = max(1, originalEndSlot - originalStartSlot)
            let startSlot = ProposalMeetupCalendarModel.clampedStartSlot(
                point.slot - pointerStartOffsetSlots,
                duration: duration
            )
            candidateEdit = ProposalMeetupCalendarCandidateEdit(
                index: candidateIndex,
                dayIndex: point.dayIndex,
                startSlot: startSlot,
                endSlot: startSlot + duration
            )
        }
    }

    func handleBoardEnded(
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) {
        defer {
            cancelBoardLongPress()
            boardTouchState = nil
            candidateEdit = nil
        }
        guard let state = boardTouchState else {
            return
        }
        let dx = value.location.x - state.startLocation.x
        let dy = value.location.y - state.startLocation.y
        switch state.mode {
        case .swiping:
            defer {
                resetWeekDragOffset()
            }
            guard ProposalMeetupCalendarModel.shouldShiftWeek(
                translationWidth: dx,
                translationHeight: dy,
                containerWidth: dayWidth * CGFloat(ProposalMeetupCalendarModel.visibleDayCount)
            ) else {
                return
            }
            onShiftWeek(dx < 0 ? 1 : -1)
        case .creating:
            guard let previewDraft else {
                return
            }
            guard ProposalMeetupCalendarModel.shouldCreateCandidateOnBoardEnd(wasLongPressed: true) else {
                previewDraftCleanup()
                return
            }
            let range = ProposalMeetupCalendarModel.normalizedSlotRange(
                startSlot: previewDraft.startSlot,
                currentSlot: previewDraft.currentSlot
            )
            previewDraftCleanup()
            onCreateDraft(days[previewDraft.dayIndex], range.lowerBound, range.upperBound)
        case .movingCandidate:
            guard let candidateIndex = state.candidateIndex,
                  let originalStartSlot = state.originalStartSlot,
                  let originalEndSlot = state.originalEndSlot,
                  let pointerStartOffsetSlots = state.pointerStartOffsetSlots
            else {
                return
            }
            let point = calendarPoint(
                from: value.location,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            let duration = max(1, originalEndSlot - originalStartSlot)
            let startSlot = ProposalMeetupCalendarModel.clampedStartSlot(
                point.slot - pointerStartOffsetSlots,
                duration: duration
            )
            candidateEdit = ProposalMeetupCalendarCandidateEdit(
                index: candidateIndex,
                dayIndex: point.dayIndex,
                startSlot: startSlot,
                endSlot: startSlot + duration
            )
            onUpdateDraft(candidateIndex, days[point.dayIndex], startSlot, startSlot + duration)
            onSelectDraft(candidateIndex)
        case .pending:
            guard !state.hasMovedBeyondTapTolerance else {
                resetWeekDragOffset()
                return
            }
            if let candidateIndex = candidateIndex(
                at: value.location,
                days: days,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            ) {
                onSelectDraft(candidateIndex)
                onOpenPlaceEntry(candidateIndex)
                return
            }
            guard ProposalMeetupCalendarModel.shouldCreateCandidateOnBoardEnd(wasLongPressed: false) else {
                resetWeekDragOffset()
                return
            }
            let endSlot = min(
                ProposalMeetupCalendarModel.slotCount,
                state.startSlot + ProposalMeetupCalendarModel.defaultDurationSlots
            )
            onCreateDraft(days[state.dayIndex], state.startSlot, endSlot)
        }
    }
}
