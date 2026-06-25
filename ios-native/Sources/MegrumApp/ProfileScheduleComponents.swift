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

struct ProfileScheduleRowView: View {
    var schedule: PersonalSchedule
    var isMine: Bool

    private var color: Color {
        isMine ? MegrumTheme.lavender : MegrumTheme.sky
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(schedule.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(isMine ? "あなた" : "相手")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.13), in: Capsule())
                }

                Text(timeRangeText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                if let placeName = schedule.placeName {
                    Label(placeName, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var timeRangeText: String {
        if schedule.allDay {
            return "終日"
        }
        let start = schedule.startAt.formatted(.dateTime.hour().minute())
        let end = schedule.endAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
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
