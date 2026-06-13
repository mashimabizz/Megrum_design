import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarEditor: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onSelectDraft: (Int) -> Void
    var onShiftWeek: (Int) -> Void
    var onSelectMonthDay: (Date) -> Void
    var onShiftMonth: (Int) -> Void
    var onCreateDraft: (Date, Int, Int) -> Void
    var onUpdateDraft: (Int, Date, Int, Int) -> Void
    var onRemoveDraft: (Int) -> Void
    var onOpenPlaceEntry: (Int) -> Void

    @State private var displayMode: ProposalMeetupCalendarDisplayMode = Self.initialDisplayMode()
    @State private var boardTouchState: ProposalMeetupCalendarBoardTouchState?
    @State private var previewDraft: ProposalMeetupCalendarPreview?
    @State private var candidateTouchState: ProposalMeetupCalendarCandidateTouchState?
    @State private var candidateEdit: ProposalMeetupCalendarCandidateEdit?
    @State private var boardLongPressTask: DispatchWorkItem?
    @State private var candidateLongPressTask: DispatchWorkItem?
    @State private var didApplyInitialHourFocus = false
    @State private var weekDragOffset: CGFloat = 0

    private let calendar = Calendar.current

    private static func initialDisplayMode(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ProposalMeetupCalendarDisplayMode {
        VisualQAPreviewMode.initialScreen(environment: environment) == .proposalMeetupMonth ? .month : .week
    }

    var body: some View {
        ProposalMeetupCalendarCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if displayMode == .week {
                        Text(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchorDate, calendar: calendar))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                    }

                    Spacer(minLength: 0)
                    ProposalMeetupCalendarModeToggle(selection: $displayMode)
                }

                switch displayMode {
                case .week:
                    weekCalendar
                case .month:
                    ProposalMeetupMonthCalendar(
                        anchorDate: anchorDate,
                        scheduleContext: scheduleContext,
                        onShiftMonth: onShiftMonth,
                        onSelectDay: { day in
                            onSelectMonthDay(day)
                            displayMode = .week
                        }
                    )
                }

            }
        }
    }

    private var weekCalendar: some View {
        GeometryReader { geometry in
            let dayWidth = ProposalMeetupCalendarModel.dayWidth(containerWidth: geometry.size.width)
            let gridWidth = ProposalMeetupCalendarModel.weekGridWidth(dayWidth: dayWidth)
            let days = ProposalMeetupCalendarModel.visibleDays(anchorDate: anchorDate, calendar: calendar)

            VStack(spacing: 8) {
                ProposalMeetupCalendarWeekHeader(
                    days: days,
                    dayWidth: dayWidth,
                    selectedDayIndex: selectedDayIndex,
                    calendar: calendar
                )
                .frame(width: gridWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(x: weekDragOffset)
                .animation(.snappy(duration: 0.18), value: weekDragOffset)
                .gesture(weekHeaderSwipeGesture(containerWidth: geometry.size.width))

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            ProposalMeetupCalendarWeekTimelineBackground(
                                days: days,
                                dayWidth: dayWidth,
                                selectedDayIndex: selectedDayIndex
                            )
                                .contentShape(Rectangle())
                                .gesture(boardGesture(days: days, dayWidth: dayWidth))
                                .zIndex(0)
                            candidateBlocks(days: days, dayWidth: dayWidth)
                                .zIndex(2)
                            ProposalMeetupCalendarWeekPreviewBlock(
                                preview: previewDraft,
                                dayWidth: dayWidth
                            )
                                .zIndex(3)
                            ProposalMeetupCalendarWeekLongPressHint(
                                isVisible: drafts.isEmpty && previewDraft == nil,
                                dayWidth: dayWidth
                            )
                                .zIndex(4)
                        }
                        .frame(width: gridWidth, alignment: .topLeading)
                        .coordinateSpace(name: "proposalMeetupCalendar")
                        .offset(x: weekDragOffset)
                        .animation(.snappy(duration: 0.18), value: weekDragOffset)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(height: 500)
                    .onAppear {
                        guard !didApplyInitialHourFocus else {
                            return
                        }
                        didApplyInitialHourFocus = true
                        DispatchQueue.main.async {
                            proxy.scrollTo(10, anchor: .top)
                        }
                    }
                }
            }
        }
        .frame(height: 552)
    }

    @ViewBuilder
    private func candidateBlocks(days: [Date], dayWidth: CGFloat) -> some View {
        ProposalMeetupCalendarWeekCandidateBlocks(
            blocks: renderedCandidateBlocks(days: days, dayWidth: dayWidth),
            onTap: { index in
                onSelectDraft(index)
                onOpenPlaceEntry(index)
            },
            onChange: { value, index, action in
                handleCandidateChanged(
                    index: index,
                    action: action,
                    value: value,
                    days: days,
                    dayWidth: dayWidth
                )
            },
            onEnd: { value, index, action in
                handleCandidateEnded(
                    index: index,
                    action: action,
                    value: value,
                    days: days,
                    dayWidth: dayWidth
                )
            },
            onRemove: onRemoveDraft
        )
    }

    private func renderedCandidateBlocks(days: [Date], dayWidth: CGFloat) -> [ProposalMeetupCalendarRenderedCandidateBlock] {
        drafts.enumerated().compactMap { index, draft in
            let renderedDraft = renderedCandidateDraft(draft, index: index, days: days)
            guard let layout = candidateLayout(for: renderedDraft, index: index, days: days, dayWidth: dayWidth) else {
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

    private func renderedCandidateDraft(
        _ draft: ProposalMeetupCandidateDraft,
        index: Int,
        days: [Date]
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

    private var selectedDayIndex: Int {
        let days = ProposalMeetupCalendarModel.visibleDays(anchorDate: anchorDate, calendar: calendar)
        guard drafts.indices.contains(selectedIndex) else {
            return 0
        }
        let selectedDay = calendar.startOfDay(for: drafts[selectedIndex].startAt)
        return days.firstIndex(where: { calendar.isDate($0, inSameDayAs: selectedDay) }) ?? 0
    }

    private func candidateLayout(
        for draft: ProposalMeetupCandidateDraft,
        index: Int,
        days: [Date],
        dayWidth: CGFloat
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

    private func candidateIndex(at location: CGPoint, days: [Date], dayWidth: CGFloat) -> Int? {
        for (index, draft) in drafts.enumerated().reversed() {
            guard let layout = candidateLayout(for: draft, index: index, days: days, dayWidth: dayWidth) else {
                continue
            }
            let rect = CGRect(x: layout.x, y: layout.y, width: layout.width, height: layout.height)
                .insetBy(dx: -6, dy: -ProposalMeetupCalendarModel.slotHeight)
            if rect.contains(location) {
                return index
            }
        }
        return nil
    }

    private func boardGesture(days: [Date], dayWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
            .onChanged { value in
                if boardTouchState == nil {
                    let point = calendarPoint(from: value.startLocation, dayWidth: dayWidth)
                    let touchedCandidateIndex = candidateIndex(at: value.startLocation, days: days, dayWidth: dayWidth)
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
                    cancelBoardLongPress()
                    if state.candidateIndex == nil {
                        state.mode = .creating
                        boardTouchState = state
                        let point = calendarPoint(from: value.location, dayWidth: dayWidth)
                        previewDraft = ProposalMeetupCalendarPreview(
                            dayIndex: state.dayIndex,
                            startSlot: state.startSlot,
                            currentSlot: point.slot
                        )
                        return
                    } else {
                        boardTouchState = nil
                        previewDraftCleanup()
                        return
                    }
                }
                if state.mode == .creating {
                    let point = calendarPoint(from: value.location, dayWidth: dayWidth)
                    previewDraft = ProposalMeetupCalendarPreview(
                        dayIndex: state.dayIndex,
                        startSlot: state.startSlot,
                        currentSlot: point.slot
                    )
                }
                if state.mode == .movingCandidate,
                   let candidateIndex = state.candidateIndex,
                   let originalStartSlot = state.originalStartSlot,
                   let originalEndSlot = state.originalEndSlot,
                   let pointerStartOffsetSlots = state.pointerStartOffsetSlots {
                    let point = calendarPoint(from: value.location, dayWidth: dayWidth)
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
            .onEnded { value in
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
                    let point = calendarPoint(from: value.location, dayWidth: dayWidth)
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
                    if let candidateIndex = candidateIndex(at: value.location, days: days, dayWidth: dayWidth) {
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

    private func weekHeaderSwipeGesture(containerWidth: CGFloat) -> some Gesture {
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

    private func resetWeekDragOffset() {
        withAnimation(.snappy(duration: 0.18)) {
            weekDragOffset = 0
        }
    }

    private func handleCandidateChanged(
        index: Int,
        action: ProposalMeetupCalendarCandidateEditAction,
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat
    ) {
        if candidateTouchState == nil {
            let original = currentCandidateEdit(index: index, days: days)
            let pointerPoint = calendarPoint(from: value.startLocation, dayWidth: dayWidth)
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
        guard let state = candidateTouchState else {
            return
        }
        let dx = value.location.x - state.startLocation.x
        let dy = value.location.y - state.startLocation.y
        if state.mode == .pending,
           hypot(dx, dy) > ProposalMeetupCalendarModel.touchCancelDistance {
            cancelCandidateLongPress()
            candidateTouchState = nil
            candidateEdit = nil
            return
        }
        guard state.mode == .editing else {
            return
        }
        let point = calendarPoint(from: value.location, dayWidth: dayWidth)
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

    private func handleCandidateEnded(
        index: Int,
        action: ProposalMeetupCalendarCandidateEditAction,
        value: DragGesture.Value,
        days: [Date],
        dayWidth: CGFloat
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
            onSelectDraft(index)
            if action == .move {
                onOpenPlaceEntry(index)
            }
            return
        }
        let point = calendarPoint(from: value.location, dayWidth: dayWidth)
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

    private func currentCandidateEdit(index: Int, days: [Date]) -> ProposalMeetupCalendarCandidateEdit {
        let draft = drafts[index]
        let day = calendar.startOfDay(for: draft.startAt)
        let dayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) ?? 0
        let startSlot = ProposalMeetupCalendarModel.slotIndex(for: draft.startAt, calendar: calendar)
        let endSlot = max(startSlot + 1, ProposalMeetupCalendarModel.slotIndex(for: draft.endAt, calendar: calendar))
        return ProposalMeetupCalendarCandidateEdit(index: index, dayIndex: dayIndex, startSlot: startSlot, endSlot: endSlot)
    }

    private func calendarPoint(from location: CGPoint, dayWidth: CGFloat) -> (dayIndex: Int, slot: Int) {
        let x = max(0, location.x - ProposalMeetupCalendarModel.timeLabelWidth)
        let columnWidth = dayWidth + ProposalMeetupCalendarModel.daySpacing
        let rawDay = Int(floor(x / max(columnWidth, 1)))
        let dayIndex = max(0, min(ProposalMeetupCalendarModel.visibleDayCount - 1, rawDay))
        let y = max(0, location.y)
        let rawSlot = Int(floor(y / ProposalMeetupCalendarModel.slotHeight))
        let slot = max(0, min(ProposalMeetupCalendarModel.slotCount - 1, rawSlot))
        return (dayIndex, slot)
    }

    private func previewDraftCleanup() {
        previewDraft = nil
        candidateEdit = nil
    }

    private func scheduleBoardLongPress(dayIndex: Int, startSlot: Int) {
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
                pointerStartOffsetSlots: state.pointerStartOffsetSlots
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

    private func cancelBoardLongPress() {
        boardLongPressTask?.cancel()
        boardLongPressTask = nil
    }

    private func scheduleCandidateLongPress(index: Int) {
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
                mode: .editing
            )
        }
        candidateLongPressTask = task
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ProposalMeetupCalendarModel.longPressDuration,
            execute: task
        )
    }

    private func cancelCandidateLongPress() {
        candidateLongPressTask?.cancel()
        candidateLongPressTask = nil
    }
}
