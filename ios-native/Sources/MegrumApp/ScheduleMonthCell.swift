import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isToday ? .white : MegrumTheme.ink)
                .frame(width: 26, height: 26)
                .background(isToday ? MegrumTheme.lavender : Color.clear, in: Circle())

            ForEach(schedules.prefix(3)) { schedule in
                HStack(spacing: 3) {
                    Circle()
                        .fill(schedule.userID == viewerID ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                    Text(schedule.title)
                        .lineLimit(1)
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(6)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}
