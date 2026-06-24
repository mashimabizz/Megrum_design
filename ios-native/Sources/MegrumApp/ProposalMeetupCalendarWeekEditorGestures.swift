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

    func scheduleBoardLongPress(dayIndex: Int, startSlot: Int) {
        cancelBoardLongPress()
        let task = DispatchWorkItem {
            guard let state = boardTouchState, state.mode == .pending else {
                return
            }
            boardTouchState = ProposalMeetupCalendarBoardTouchState(
                startTime: state.startTime,
                startLocation: state.startLocation,
                dayIndex: state.dayIndex,
                startSlot: state.startSlot,
                mode: state.candidateIndex == nil ? .creating : .movingCandidate,
                candidateIndex: state.candidateIndex,
                originalDayIndex: state.originalDayIndex,
                originalStartSlot: state.originalStartSlot,
                originalEndSlot: state.originalEndSlot,
                pointerStartOffsetSlots: state.pointerStartOffsetSlots,
                hasMovedBeyondTapTolerance: state.hasMovedBeyondTapTolerance
            )
            if let candidateIndex = state.candidateIndex,
               let originalDayIndex = state.originalDayIndex,
               let originalStartSlot = state.originalStartSlot,
               let originalEndSlot = state.originalEndSlot {
                candidateEdit = ProposalMeetupCalendarCandidateEdit(
                    index: candidateIndex,
                    dayIndex: originalDayIndex,
                    startSlot: originalStartSlot,
                    endSlot: originalEndSlot
                )
            } else {
                previewDraft = ProposalMeetupCalendarPreview(
                    dayIndex: dayIndex,
                    startSlot: startSlot,
                    currentSlot: startSlot + ProposalMeetupCalendarModel.defaultDurationSlots - 1
                )
            }
        }
        boardLongPressTask = task
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ProposalMeetupCalendarModel.longPressDuration,
            execute: task
        )
    }

    func cancelBoardLongPress() {
        boardLongPressTask?.cancel()
        boardLongPressTask = nil
    }

    func scheduleCandidateLongPress(index: Int) {
        cancelCandidateLongPress()
        let task = DispatchWorkItem {
            guard let state = candidateTouchState,
                  state.mode == .pending,
                  state.draftIndex == index
            else {
                return
            }
            candidateTouchState = ProposalMeetupCalendarCandidateTouchState(
                startTime: state.startTime,
                startLocation: state.startLocation,
                draftIndex: state.draftIndex,
                action: state.action,
                originalDayIndex: state.originalDayIndex,
                originalStartSlot: state.originalStartSlot,
                originalEndSlot: state.originalEndSlot,
                pointerStartOffsetSlots: state.pointerStartOffsetSlots,
                mode: .editing,
                hasMovedBeyondTapTolerance: state.hasMovedBeyondTapTolerance
            )
        }
        candidateLongPressTask = task
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ProposalMeetupCalendarModel.longPressDuration,
            execute: task
        )
    }

    func cancelCandidateLongPress() {
        candidateLongPressTask?.cancel()
        candidateLongPressTask = nil
    }
}

private extension ProposalMeetupCalendarWeekEditor {
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
