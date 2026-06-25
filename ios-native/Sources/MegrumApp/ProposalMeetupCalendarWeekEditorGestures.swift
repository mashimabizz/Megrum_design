import Foundation
import SwiftUI

extension ProposalMeetupCalendarWeekEditor {
    func boardGesture(
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
            .onChanged { value in
                handleBoardChanged(
                    value: value,
                    days: days,
                    dayWidth: dayWidth,
                    containerWidth: containerWidth
                )
            }
            .onEnded { value in
                handleBoardEnded(
                    value: value,
                    days: days,
                    dayWidth: dayWidth,
                    containerWidth: containerWidth
                )
            }
    }

    func weekHeaderSwipeGesture(containerWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 10, abs(dx) > abs(dy) * 1.08 else {
                    return
                }
                cancelBoardLongPress()
                weekDragOffset = ProposalMeetupCalendarModel.clampedWeekDragOffset(dx, containerWidth: containerWidth)
            }
            .onEnded { value in
                defer {
                    resetWeekDragOffset()
                }
                guard ProposalMeetupCalendarModel.shouldShiftWeek(
                    translationWidth: value.translation.width,
                    translationHeight: value.translation.height,
                    containerWidth: containerWidth
                ) else {
                    return
                }
                onShiftWeek(value.translation.width < 0 ? 1 : -1)
            }
    }

    func handleCandidateChanged(
        index: Int,
        action: ProposalMeetupCalendarCandidateEditAction,
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) {
        if candidateTouchState == nil {
            let original = currentCandidateEdit(index: index, days: days)
            let pointerPoint = calendarPoint(
                from: value.startLocation,
                dayWidth: dayWidth,
                containerWidth: containerWidth
            )
            let pointerOffset = max(0, min(original.endSlot - original.startSlot - 1, pointerPoint.slot - original.startSlot))
            candidateTouchState = ProposalMeetupCalendarCandidateTouchState(
                startTime: Date(),
                startLocation: value.startLocation,
                draftIndex: index,
                action: action,
                originalDayIndex: original.dayIndex,
                originalStartSlot: original.startSlot,
                originalEndSlot: original.endSlot,
                pointerStartOffsetSlots: pointerOffset,
                mode: .pending
            )
            scheduleCandidateLongPress(index: index)
        }
        guard var state = candidateTouchState else {
            return
        }
        let dx = value.location.x - state.startLocation.x
        let dy = value.location.y - state.startLocation.y
        if state.mode == .pending,
           hypot(dx, dy) > ProposalMeetupCalendarModel.touchCancelDistance {
            state.hasMovedBeyondTapTolerance = true
            candidateTouchState = state
        }
        guard state.mode == .editing else {
            return
        }
        let point = calendarPoint(
            from: value.location,
            dayWidth: dayWidth,
            containerWidth: containerWidth
        )
        let duration = max(1, state.originalEndSlot - state.originalStartSlot)
        switch state.action {
        case .move:
            let startSlot = ProposalMeetupCalendarModel.clampedStartSlot(point.slot - state.pointerStartOffsetSlots, duration: duration)
            candidateEdit = ProposalMeetupCalendarCandidateEdit(
                index: index,
                dayIndex: point.dayIndex,
                startSlot: startSlot,
                endSlot: startSlot + duration
            )
        case .resizeEnd:
            let endSlot = max(state.originalStartSlot + 1, min(ProposalMeetupCalendarModel.slotCount, point.slot + 1))
            candidateEdit = ProposalMeetupCalendarCandidateEdit(
                index: index,
                dayIndex: state.originalDayIndex,
                startSlot: state.originalStartSlot,
                endSlot: endSlot
            )
        }
    }

    func handleCandidateEnded(
        index: Int,
        action: ProposalMeetupCalendarCandidateEditAction,
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) {
        defer {
            cancelCandidateLongPress()
            candidateTouchState = nil
            candidateEdit = nil
        }
        guard let state = candidateTouchState else {
            return
        }
        if state.mode == .pending {
            guard !state.hasMovedBeyondTapTolerance else {
                return
            }
            onSelectDraft(index)
            if action == .move {
                onOpenPlaceEntry(index)
            }
            return
        }
        let point = calendarPoint(
            from: value.location,
            dayWidth: dayWidth,
            containerWidth: containerWidth
        )
        let duration = max(1, state.originalEndSlot - state.originalStartSlot)
        let edit: ProposalMeetupCalendarCandidateEdit
        switch action {
        case .move:
            let startSlot = ProposalMeetupCalendarModel.clampedStartSlot(point.slot - state.pointerStartOffsetSlots, duration: duration)
            edit = ProposalMeetupCalendarCandidateEdit(index: index, dayIndex: point.dayIndex, startSlot: startSlot, endSlot: startSlot + duration)
        case .resizeEnd:
            let endSlot = max(state.originalStartSlot + 1, min(ProposalMeetupCalendarModel.slotCount, point.slot + 1))
            edit = ProposalMeetupCalendarCandidateEdit(index: index, dayIndex: state.originalDayIndex, startSlot: state.originalStartSlot, endSlot: endSlot)
        }
        onUpdateDraft(index, days[edit.dayIndex], edit.startSlot, edit.endSlot)
        onSelectDraft(index)
    }

    func previewDraftCleanup() {
        previewDraft = nil
        candidateEdit = nil
    }

    func resetWeekDragOffset() {
        withAnimation(.snappy(duration: 0.18)) {
            weekDragOffset = 0
        }
    }

}
