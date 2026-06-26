import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupMonthDayCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var scheduleContext: ProposalScheduleContext
    var onSelect: () -> Void

    private var cellBackgroundColor: Color {
        isToday ? MegrumTheme.lavender.opacity(0.12) : MegrumTheme.ink.opacity(0.035)
    }

    private var cellStrokeColor: Color {
        isToday ? MegrumTheme.lavender.opacity(0.34) : MegrumTheme.ink.opacity(0.06)
    }

    var body: some View {
        Button(action: onSelect) {
            ProposalMeetupMonthDayCellContent(
                day: day,
                schedules: schedules,
                isToday: isToday,
                scheduleContext: scheduleContext
            )
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
            .background(
                cellBackgroundColor,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(cellStrokeColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(.dateTime.month().day()))を週表示で開く")
    }
}

private struct ProposalMeetupMonthDayCellContent: View {
    let day: Date
    let schedules: [PersonalSchedule]
    let isToday: Bool
    let scheduleContext: ProposalScheduleContext

    private var dayNumberColor: Color {
        isToday ? MegrumTheme.lavender : MegrumTheme.ink
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(dayNumberColor)

            ProposalMeetupMonthScheduleList(
                schedules: schedules,
                scheduleContext: scheduleContext
            )

            Spacer(minLength: 0)
        }
    }
}

private struct ProposalMeetupMonthScheduleList: View {
    let schedules: [PersonalSchedule]
    let scheduleContext: ProposalScheduleContext

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(schedules.prefix(3)) { schedule in
                ProposalMeetupMonthSchedulePill(
                    schedule: schedule,
                    scheduleContext: scheduleContext
                )
            }

            if schedules.count > 3 {
                Text("+\(schedules.count - 3)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

private struct ProposalMeetupMonthSchedulePill: View {
    let schedule: PersonalSchedule
    let scheduleContext: ProposalScheduleContext

    private var label: String {
        if schedule.allDay {
            return schedule.title
        }
        return "\(schedule.startAt.formatted(.dateTime.hour().minute())) \(schedule.title)"
    }

    private var backgroundColor: Color {
        (scheduleContext.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky)
            .opacity(scheduleContext.isMine(schedule) ? 0.22 : 0.34)
    }

    var body: some View {
        Text(label)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}

extension View {
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
