import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ScheduleLoadingNotice: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("スケジュールを読み込んでいます")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct ScheduleMonthGrid: View {
    var monthTitle: String
    var monthGridDays: [Date?]
    var calendar: Calendar
    var viewerID: UUID?
    var schedulesForDay: (Date) -> [PersonalSchedule]
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void

    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthTitle)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Button {
                    onPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(MegrumTheme.lavender)

                Button {
                    onNextMonth()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(MegrumTheme.lavender)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        ScheduleMonthCell(
                            day: day,
                            schedules: schedulesForDay(day),
                            isToday: calendar.isDateInToday(day),
                            viewerID: viewerID
                        )
                    } else {
                        Color.clear
                            .frame(height: 76)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}
