import MegrumCore
import MegrumDesign
import SwiftUI

struct ProfileScheduleHeader: View {
    var displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(displayName)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("公開されている予定")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileScheduleDayCard: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(day.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                if Calendar.current.isDateInToday(day) {
                    Text("今日")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.lavender, in: Capsule())
                }
            }

            if schedules.isEmpty {
                Text("予定なし")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(schedules) { schedule in
                    ProfileScheduleRowView(schedule: schedule, isMine: schedule.userID == viewerID)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}

struct ProfileScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Calendar.current.isDateInToday(day) ? MegrumTheme.lavender : MegrumTheme.ink)

            ForEach(schedules.prefix(2)) { schedule in
                HStack(spacing: 4) {
                    Circle()
                        .fill(schedule.userID == viewerID ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                    Text(schedule.title)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 64, alignment: .topLeading)
        .padding(6)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
