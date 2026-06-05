import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum ProposalStepSwipeNavigator {
    static let minimumHorizontalDistance: CGFloat = 56
    static let horizontalPriorityRatio: CGFloat = 1.35

    static func destination(
        from currentStep: ProposalCreateStep,
        translationWidth: CGFloat,
        translationHeight: CGFloat,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        let absX = abs(translationWidth)
        let absY = abs(translationHeight)
        guard absX >= minimumHorizontalDistance, absX >= absY * horizontalPriorityRatio else {
            return nil
        }
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep) else {
            return nil
        }
        let destinationIndex = translationWidth < 0 ? currentIndex + 1 : currentIndex - 1
        guard visibleSteps.indices.contains(destinationIndex) else {
            return nil
        }
        return visibleSteps[destinationIndex]
    }
}

enum ProposalMeetupCalendarModel {
    static let visibleDayCount = 7
    static let slotMinutes = 15
    static let slotCount = 24 * (60 / slotMinutes)
    static let slotHeight: CGFloat = 16
    static let timeLabelWidth: CGFloat = 52
    static let daySpacing: CGFloat = 0
    static let minimumDayWidth: CGFloat = 34
    static let swipeThreshold: CGFloat = 56
    static let longPressDuration: TimeInterval = 0.28
    static let touchCancelDistance: CGFloat = 12
    static let defaultDurationSlots = 2
    static let edgeCarryRatio: CGFloat = 0.42

    static func visibleDays(anchorDate: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<visibleDayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    static func shiftedAnchor(anchorDate: Date, direction: Int, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .day, value: direction * visibleDayCount, to: start) ?? start
    }

    static func monthGridDays(anchorDate: Date, calendar: Calendar = .current) -> [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = calendar.component(.weekday, from: month.start) - 1
        var days: [Date?] = Array(repeating: nil, count: max(0, leadingBlanks))
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    static func slotIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let slot = hour * (60 / slotMinutes) + Int(Double(minute) / Double(slotMinutes))
        return max(0, min(slotCount - 1, slot))
    }

    static func slotIndex(forHour hour: Int) -> Int {
        max(0, min(slotCount - 1, hour * (60 / slotMinutes)))
    }

    static func normalizedSlotRange(startSlot: Int, currentSlot: Int) -> ClosedRange<Int> {
        let lower = max(0, min(startSlot, currentSlot))
        let upper = min(slotCount, max(startSlot + 1, currentSlot + 1))
        return lower...upper
    }

    static func clampedStartSlot(_ value: Int, duration: Int) -> Int {
        max(0, min(slotCount - max(duration, 1), value))
    }

    static func date(for day: Date, slot: Int, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: slot * slotMinutes, to: start) ?? start
    }

    static func shouldCreateCandidateOnBoardEnd(wasLongPressed: Bool) -> Bool {
        wasLongPressed
    }

    static func dayWidth(containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else {
            return minimumDayWidth
        }
        let spacingWidth = daySpacing * CGFloat(visibleDayCount - 1)
        let available = containerWidth - timeLabelWidth - spacingWidth
        return max(minimumDayWidth, floor(available / CGFloat(visibleDayCount)))
    }

    static func weekdayLabel(for date: Date, calendar: Calendar = .current) -> String {
        let labels = ["日", "月", "火", "水", "木", "金", "土"]
        return labels[max(0, min(labels.count - 1, calendar.component(.weekday, from: date) - 1))]
    }

    static func dayNumberLabel(for date: Date, calendar: Calendar = .current) -> String {
        "\(calendar.component(.day, from: date))"
    }

    static func monthDayCellWidth(containerWidth: CGFloat) -> CGFloat {
        max(42, floor(containerWidth * 0.1372))
    }

    static func monthGridWidth(containerWidth: CGFloat) -> CGFloat {
        let cellWidth = monthDayCellWidth(containerWidth: containerWidth)
        return cellWidth * CGFloat(visibleDayCount) + 4 * CGFloat(visibleDayCount - 1)
    }

    static func monthGridHeight(rowCount: Int) -> CGFloat {
        let weekdayHeight: CGFloat = 14
        let rowHeight: CGFloat = 74
        let rowSpacing: CGFloat = 4
        let rows = CGFloat(max(1, rowCount))
        return weekdayHeight + rowSpacing + rows * rowHeight + max(0, rows - 1) * rowSpacing
    }

    static func weekGridWidth(dayWidth: CGFloat) -> CGFloat {
        timeLabelWidth
            + dayWidth * CGFloat(visibleDayCount)
            + daySpacing * CGFloat(visibleDayCount - 1)
    }

    static func clampedWeekDragOffset(_ translationWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        let maxDrag = max(1, containerWidth) * edgeCarryRatio
        return max(-maxDrag, min(maxDrag, translationWidth))
    }

    static func shouldShiftWeek(translationWidth: CGFloat, translationHeight: CGFloat, containerWidth: CGFloat) -> Bool {
        let threshold = min(96, max(44, containerWidth * 0.22))
        return abs(translationWidth) >= threshold
            && abs(translationWidth) >= abs(translationHeight) * 1.25
    }
}

extension ProposalMeetupCandidateDraft {
    func applyingCalendarRange(
        day: Date,
        startSlot: Int,
        endSlot: Int,
        calendar: Calendar = .current
    ) -> ProposalMeetupCandidateDraft {
        var draft = self
        draft.startAt = ProposalMeetupCalendarModel.date(for: day, slot: startSlot, calendar: calendar)
        draft.endAt = ProposalMeetupCalendarModel.date(for: day, slot: endSlot, calendar: calendar)
        return draft
    }
}

private struct ProposalMeetupCalendarPreview: Equatable {
    var dayIndex: Int
    var startSlot: Int
    var currentSlot: Int
}

private enum ProposalMeetupCalendarCandidateEditAction {
    case move
    case resizeEnd
}

private struct ProposalMeetupCalendarCandidateEdit: Equatable {
    var index: Int
    var dayIndex: Int
    var startSlot: Int
    var endSlot: Int
}

private enum ProposalMeetupCalendarBoardTouchMode {
    case pending
    case swiping
    case creating
}

private struct ProposalMeetupCalendarBoardTouchState {
    var startTime: Date
    var startLocation: CGPoint
    var dayIndex: Int
    var startSlot: Int
    var mode: ProposalMeetupCalendarBoardTouchMode
}

private enum ProposalMeetupCalendarCandidateTouchMode {
    case pending
    case editing
}

enum ProposalMeetupCalendarDisplayMode: String, CaseIterable, Identifiable, Equatable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            "週"
        case .month:
            "月"
        }
    }
}

private struct ProposalMeetupCalendarCandidateTouchState {
    var startTime: Date
    var startLocation: CGPoint
    var draftIndex: Int
    var action: ProposalMeetupCalendarCandidateEditAction
    var originalDayIndex: Int
    var originalStartSlot: Int
    var originalEndSlot: Int
    var pointerStartOffsetSlots: Int
    var mode: ProposalMeetupCalendarCandidateTouchMode
}

struct ProposalMeetupCalendarEditor: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onSelectDraft: (Int) -> Void
    var onShiftWeek: (Int) -> Void
    var onSelectMonthDay: (Date) -> Void
    var onCreateDraft: (Date, Int, Int) -> Void
    var onUpdateDraft: (Int, Date, Int, Int) -> Void
    var onOpenPlaceEntry: () -> Void

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
                HStack(spacing: ProposalMeetupCalendarModel.daySpacing) {
                    Color.clear
                        .frame(width: ProposalMeetupCalendarModel.timeLabelWidth, height: 1)
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 2) {
                            Text(ProposalMeetupCalendarModel.weekdayLabel(for: day, calendar: calendar))
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                            Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day, calendar: calendar))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(selectedDayColor(index: index))
                        }
                        .frame(width: dayWidth)
                    }
                }
                .frame(width: gridWidth, alignment: .leading)
                .offset(x: weekDragOffset)
                .animation(.snappy(duration: 0.18), value: weekDragOffset)
                .gesture(weekHeaderSwipeGesture(containerWidth: geometry.size.width))

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            calendarBackground(days: days, dayWidth: dayWidth)
                            candidateBlocks(days: days, dayWidth: dayWidth)
                            previewBlock(dayWidth: dayWidth)
                            weekLongPressHint(dayWidth: dayWidth)
                        }
                        .frame(width: gridWidth, alignment: .topLeading)
                        .coordinateSpace(name: "proposalMeetupCalendar")
                        .contentShape(Rectangle())
                        .gesture(boardGesture(days: days, dayWidth: dayWidth))
                        .offset(x: weekDragOffset)
                        .animation(.snappy(duration: 0.18), value: weekDragOffset)
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

    private func calendarBackground(days: [Date], dayWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: ProposalMeetupCalendarModel.daySpacing) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(width: ProposalMeetupCalendarModel.timeLabelWidth, height: ProposalMeetupCalendarModel.slotHeight * 4, alignment: .topTrailing)
                        .id(hour)
                }
            }

            ForEach(Array(days.enumerated()), id: \.offset) { index, _ in
                VStack(spacing: 0) {
                    ForEach(0..<ProposalMeetupCalendarModel.slotCount, id: \.self) { slot in
                        Rectangle()
                            .fill(slot.isMultiple(of: 4) ? MegrumTheme.sky.opacity(0.08) : Color.white.opacity(0.44))
                            .frame(width: dayWidth, height: ProposalMeetupCalendarModel.slotHeight)
                            .overlay(alignment: .topLeading) {
                                Rectangle()
                                    .fill(Color.white.opacity(slot.isMultiple(of: 4) ? 0.78 : 0.46))
                                    .frame(height: 1)
                            }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selectedDayColor(index: index).opacity(index == selectedDayIndex ? 0.34 : 0.12), lineWidth: index == selectedDayIndex ? 1.4 : 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func candidateBlocks(days: [Date], dayWidth: CGFloat) -> some View {
        ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
            if let layout = candidateLayout(for: draft, index: index, days: days, dayWidth: dayWidth) {
                ProposalMeetupCalendarCandidateBlock(
                    draft: draft,
                    index: index,
                    isSelected: index == selectedIndex,
                    height: layout.height,
                    onMoveChanged: { value in
                        handleCandidateChanged(
                            index: index,
                            action: .move,
                            value: value,
                            days: days,
                            dayWidth: dayWidth
                        )
                    },
                    onMoveEnded: { value in
                        handleCandidateEnded(
                            index: index,
                            action: .move,
                            value: value,
                            days: days,
                            dayWidth: dayWidth
                        )
                    },
                    onResizeChanged: { value in
                        handleCandidateChanged(
                            index: index,
                            action: .resizeEnd,
                            value: value,
                            days: days,
                            dayWidth: dayWidth
                        )
                    },
                    onResizeEnded: { value in
                        handleCandidateEnded(
                            index: index,
                            action: .resizeEnd,
                            value: value,
                            days: days,
                            dayWidth: dayWidth
                        )
                    }
                )
                .frame(width: layout.width, height: layout.height)
                .offset(x: layout.x, y: layout.y)
            }
        }
    }

    @ViewBuilder
    private func previewBlock(dayWidth: CGFloat) -> some View {
        if let previewDraft {
            let range = ProposalMeetupCalendarModel.normalizedSlotRange(
                startSlot: previewDraft.startSlot,
                currentSlot: previewDraft.currentSlot
            )
            let height = CGFloat(max(1, range.upperBound - range.lowerBound)) * ProposalMeetupCalendarModel.slotHeight - 4
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MegrumTheme.lavender.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MegrumTheme.lavender.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                }
                .frame(width: dayWidth - 8, height: max(20, height))
                .offset(
                    x: ProposalMeetupCalendarModel.timeLabelWidth
                        + CGFloat(previewDraft.dayIndex) * (dayWidth + ProposalMeetupCalendarModel.daySpacing)
                        + 4,
                    y: CGFloat(range.lowerBound) * ProposalMeetupCalendarModel.slotHeight + 2
                )
        }
    }

    @ViewBuilder
    private func weekLongPressHint(dayWidth: CGFloat) -> some View {
        if drafts.allSatisfy({ $0.normalizedPlaceName.isEmpty }), previewDraft == nil {
            Text("長押しで時間帯を選択できるよ")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background(MegrumTheme.ink.opacity(0.36), in: Capsule())
                .offset(
                    x: ProposalMeetupCalendarModel.timeLabelWidth
                        + (dayWidth + ProposalMeetupCalendarModel.daySpacing) * 1.55,
                    y: CGFloat(ProposalMeetupCalendarModel.slotIndex(forHour: 12)) * ProposalMeetupCalendarModel.slotHeight
                )
        }
    }

    private var selectedDayIndex: Int {
        let days = ProposalMeetupCalendarModel.visibleDays(anchorDate: anchorDate, calendar: calendar)
        guard drafts.indices.contains(selectedIndex) else {
            return 0
        }
        let selectedDay = calendar.startOfDay(for: drafts[selectedIndex].startAt)
        return days.firstIndex(where: { calendar.isDate($0, inSameDayAs: selectedDay) }) ?? 0
    }

    private func selectedDayColor(index: Int) -> Color {
        index == selectedDayIndex ? MegrumTheme.lavender : MegrumTheme.ink
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

    private func boardGesture(days: [Date], dayWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
            .onChanged { value in
                if boardTouchState == nil {
                    let point = calendarPoint(from: value.startLocation, dayWidth: dayWidth)
                    boardTouchState = ProposalMeetupCalendarBoardTouchState(
                        startTime: Date(),
                        startLocation: value.startLocation,
                        dayIndex: point.dayIndex,
                        startSlot: point.slot,
                        mode: .pending
                    )
                    scheduleBoardLongPress(dayIndex: point.dayIndex, startSlot: point.slot)
                }
                guard var state = boardTouchState else {
                    return
                }
                let dx = value.location.x - state.startLocation.x
                let dy = value.location.y - state.startLocation.y
                if state.mode == .pending,
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
                if state.mode == .creating {
                    let point = calendarPoint(from: value.location, dayWidth: dayWidth)
                    previewDraft = ProposalMeetupCalendarPreview(
                        dayIndex: point.dayIndex,
                        startSlot: state.startSlot,
                        currentSlot: point.slot
                    )
                }
            }
            .onEnded { value in
                defer {
                    cancelBoardLongPress()
                    boardTouchState = nil
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
                case .pending:
                    guard ProposalMeetupCalendarModel.shouldCreateCandidateOnBoardEnd(wasLongPressed: false) else {
                        resetWeekDragOffset()
                        return
                    }
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
                onOpenPlaceEntry()
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
                mode: .creating
            )
            previewDraft = ProposalMeetupCalendarPreview(
                dayIndex: dayIndex,
                startSlot: startSlot,
                currentSlot: startSlot + ProposalMeetupCalendarModel.defaultDurationSlots - 1
            )
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

private struct ProposalMeetupCalendarCandidateBlock: View {
    var draft: ProposalMeetupCandidateDraft
    var index: Int
    var isSelected: Bool
    var height: CGFloat
    var onMoveChanged: (DragGesture.Value) -> Void
    var onMoveEnded: (DragGesture.Value) -> Void
    var onResizeChanged: (DragGesture.Value) -> Void
    var onResizeEnded: (DragGesture.Value) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("候補\(index + 1)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(draft.normalizedPlaceName.isEmpty ? "場所未入力" : draft.normalizedPlaceName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 16)

            Rectangle()
                .fill(Color.white.opacity(0.7))
                .frame(height: 8)
                .overlay {
                    Capsule()
                        .fill(MegrumTheme.lavender.opacity(0.84))
                        .frame(width: 28, height: 4)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                        .onChanged(onResizeChanged)
                        .onEnded(onResizeEnded)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(isSelected ? MegrumTheme.lavender : MegrumTheme.sky, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.9 : 0.62), lineWidth: isSelected ? 1.5 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("proposalMeetupCalendar"))
                .onChanged(onMoveChanged)
                .onEnded(onMoveEnded)
        )
    }
}

private struct ProposalMeetupCalendarModeToggle: View {
    @Binding var selection: ProposalMeetupCalendarDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProposalMeetupCalendarDisplayMode.allCases) { mode in
                Button {
                    withAnimation(.snappy) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(selection == mode ? .white : MegrumTheme.muted)
                        .frame(width: 38, height: 30)
                        .background(selection == mode ? MegrumTheme.lavender : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("カレンダー\(mode.title)表示")
            }
        }
        .padding(3)
        .background(MegrumTheme.ink.opacity(0.07), in: Capsule())
    }
}

private struct ProposalMeetupMonthCalendar: View {
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onSelectDay: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        let days = ProposalMeetupCalendarModel.monthGridDays(anchorDate: anchorDate, calendar: calendar)
        let rowCount = max(1, days.count / ProposalMeetupCalendarModel.visibleDayCount)

        GeometryReader { geometry in
            let cellWidth = ProposalMeetupCalendarModel.monthDayCellWidth(containerWidth: geometry.size.width)
            let gridWidth = ProposalMeetupCalendarModel.monthGridWidth(containerWidth: geometry.size.width)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: cellWidth)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        if let day {
                            ProposalMeetupMonthDayCell(
                                day: day,
                                schedules: scheduleContext.schedules(on: day, calendar: calendar),
                                isToday: calendar.isDateInToday(day),
                                scheduleContext: scheduleContext,
                                onSelect: {
                                    onSelectDay(day)
                                }
                            )
                        } else {
                            Color.clear
                                .frame(width: cellWidth, height: 74)
                        }
                    }
                }
            }
            .frame(width: gridWidth, alignment: .leading)
        }
        .padding(.top, 4)
        .frame(height: ProposalMeetupCalendarModel.monthGridHeight(rowCount: rowCount))
        .clipped()
    }
}

private struct ProposalMeetupMonthDayCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var scheduleContext: ProposalScheduleContext
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 5) {
                Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(isToday ? MegrumTheme.lavender : MegrumTheme.ink)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(schedules.prefix(3)) { schedule in
                        Text(monthScheduleLabel(for: schedule))
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (scheduleContext.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky).opacity(scheduleContext.isMine(schedule) ? 0.22 : 0.34),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                    }

                    if schedules.count > 3 {
                        Text("+\(schedules.count - 3)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
            .background(
                isToday ? MegrumTheme.lavender.opacity(0.12) : MegrumTheme.ink.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isToday ? MegrumTheme.lavender.opacity(0.34) : MegrumTheme.ink.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(.dateTime.month().day()))を週表示で開く")
    }

    private func monthScheduleLabel(for schedule: PersonalSchedule) -> String {
        if schedule.allDay {
            return schedule.title
        }
        return "\(schedule.startAt.formatted(.dateTime.hour().minute())) \(schedule.title)"
    }
}

private struct ProposalMeetupCalendarCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
    }
}
