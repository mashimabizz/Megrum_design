import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalScheduleMonthGrid: View {
    var context: ProposalScheduleContext
    var anchorDate: Date

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(anchorDate.formatted(.dateTime.year().month(.wide)))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let schedules = context.schedules(on: day, calendar: calendar)
                        ProposalScheduleMonthCell(
                            day: day,
                            schedules: schedules,
                            isToday: calendar.isDateInToday(day),
                            context: context
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    private var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
}

private struct ProposalScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var context: ProposalScheduleContext

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(isToday ? .white : MegrumTheme.ink)
                .frame(width: 22, height: 22)
                .background(isToday ? MegrumTheme.lavender : Color.clear, in: Circle())

            HStack(spacing: 3) {
                ForEach(schedules.prefix(3)) { schedule in
                    Circle()
                        .fill(context.isMine(schedule) ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .padding(5)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
