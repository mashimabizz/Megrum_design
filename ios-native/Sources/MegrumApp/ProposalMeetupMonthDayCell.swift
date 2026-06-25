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
