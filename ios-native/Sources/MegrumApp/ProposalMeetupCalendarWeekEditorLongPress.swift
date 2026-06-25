import Foundation

extension ProposalMeetupCalendarWeekEditor {
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
