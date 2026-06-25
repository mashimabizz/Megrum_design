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

private extension View {
    func proposalMeetupMonthNavigationButtonStyle(accessibilityLabel: String) -> some View {
        self
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(width: 34, height: 30)
            .background(.white.opacity(0.72), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
            .accessibilityLabel(accessibilityLabel)
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
                                scheduleBackgroundColor(for: schedule),
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

    private func scheduleBackgroundColor(for schedule: PersonalSchedule) -> Color {
        (scheduleContext.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky)
            .opacity(scheduleContext.isMine(schedule) ? 0.22 : 0.34)
    }
}
