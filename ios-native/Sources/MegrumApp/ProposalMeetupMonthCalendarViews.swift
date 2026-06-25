import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupMonthCalendar: View {
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onShiftMonth: (Int) -> Void
    var onSelectDay: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        let days = ProposalMeetupCalendarModel.monthGridDays(anchorDate: anchorDate, calendar: calendar)
        let rowCount = max(1, days.count / ProposalMeetupCalendarModel.monthColumnCount)

        GeometryReader { geometry in
            let cellWidth = ProposalMeetupCalendarModel.monthDayCellWidth(containerWidth: geometry.size.width)
            let gridWidth = ProposalMeetupCalendarModel.monthGridWidth(containerWidth: geometry.size.width)

            VStack(alignment: .leading, spacing: ProposalMeetupCalendarModel.monthHeaderSpacing) {
                monthNavigationHeader

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(weekdayLabels, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                                .frame(width: cellWidth)
                        }
                    }

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.fixed(cellWidth), spacing: 4),
                            count: ProposalMeetupCalendarModel.monthColumnCount
                        ),
                        spacing: 4
                    ) {
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
            }
            .frame(width: gridWidth, alignment: .leading)
        }
        .padding(.top, 4)
        .frame(height: ProposalMeetupCalendarModel.monthGridHeight(rowCount: rowCount))
        .clipped()
    }

    private var monthNavigationHeader: some View {
        HStack(spacing: 8) {
            Text(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchorDate, calendar: calendar))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Button("◀︎") {
                onShiftMonth(-1)
            }
            .proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: "前の月へ")

            Button("▶︎") {
                onShiftMonth(1)
            }
            .proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: "次の月へ")

            Spacer(minLength: 0)
        }
        .frame(height: ProposalMeetupCalendarModel.monthHeaderHeight)
    }
}
