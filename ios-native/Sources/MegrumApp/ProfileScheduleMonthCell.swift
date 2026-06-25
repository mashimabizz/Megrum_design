import MegrumCore
import MegrumDesign
import SwiftUI

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
