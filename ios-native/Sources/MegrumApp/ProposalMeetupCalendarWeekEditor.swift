import Foundation
import MegrumCore
import SwiftUI

struct ProposalMeetupCalendarWeekEditor: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var anchorDate: Date
    var onSelectDraft: (Int) -> Void
    var onShiftWeek: (Int) -> Void
    var onCreateDraft: (Date, Int, Int) -> Void
    var onUpdateDraft: (Int, Date, Int, Int) -> Void
    var onRemoveDraft: (Int) -> Void
    var onOpenPlaceEntry: (Int) -> Void

    @State var boardTouchState: ProposalMeetupCalendarBoardTouchState?
    @State var previewDraft: ProposalMeetupCalendarPreview?
    @State var candidateTouchState: ProposalMeetupCalendarCandidateTouchState?
    @State var candidateEdit: ProposalMeetupCalendarCandidateEdit?
    @State var boardLongPressTask: DispatchWorkItem?
    @State var candidateLongPressTask: DispatchWorkItem?
    @State private var didApplyInitialHourFocus = false
    @State var weekDragOffset: CGFloat = 0

    private let calendar = Calendar.current

    var body: some View {
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
                            .gesture(
                                boardGesture(
                                    days: days,
                                    dayWidth: dayWidth,
                                    containerWidth: gridWidth
                                )
                            )
                            .zIndex(0)
                            candidateBlocks(
                                days: days,
                                dayWidth: dayWidth,
                                containerWidth: gridWidth
                            )
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
    private func candidateBlocks(
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) -> some View {
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
                    dayWidth: dayWidth,
                    containerWidth: containerWidth
                )
            },
            onEnd: { value, index, action in
                handleCandidateEnded(
                    index: index,
                    action: action,
                    value: value,
                    days: days,
                    dayWidth: dayWidth,
                    containerWidth: containerWidth
                )
            },
            onRemove: onRemoveDraft
        )
    }

    private func renderedCandidateBlocks(days: [Date], dayWidth: CGFloat) -> [ProposalMeetupCalendarRenderedCandidateBlock] {
        ProposalMeetupCalendarLayoutBuilder.renderedCandidateBlocks(
            drafts: drafts,
            selectedIndex: selectedIndex,
            candidateEdit: candidateEdit,
            days: days,
            dayWidth: dayWidth,
            calendar: calendar
        )
    }

    private var selectedDayIndex: Int {
        ProposalMeetupCalendarLayoutBuilder.selectedDayIndex(
            drafts: drafts,
            selectedIndex: selectedIndex,
            anchorDate: anchorDate,
            calendar: calendar
        )
    }

    func candidateIndex(
        at location: CGPoint,
        days: [Date],
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) -> Int? {
        ProposalMeetupCalendarLayoutBuilder.candidateIndex(
            at: location,
            drafts: drafts,
            candidateEdit: candidateEdit,
            days: days,
            dayWidth: dayWidth,
            containerWidth: containerWidth,
            calendar: calendar
        )
    }

    func currentCandidateEdit(index: Int, days: [Date]) -> ProposalMeetupCalendarCandidateEdit {
        ProposalMeetupCalendarLayoutBuilder.currentCandidateEdit(
            index: index,
            drafts: drafts,
            days: days,
            calendar: calendar
        )
    }

    func calendarPoint(
        from location: CGPoint,
        dayWidth: CGFloat,
        containerWidth: CGFloat
    ) -> (dayIndex: Int, slot: Int) {
        ProposalMeetupCalendarModel.weekCalendarPoint(
            from: location,
            containerWidth: containerWidth,
            dayWidth: dayWidth
        )
    }
}
