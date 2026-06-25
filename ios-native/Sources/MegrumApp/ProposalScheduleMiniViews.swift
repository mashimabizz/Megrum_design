import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalSelectedScheduleOverlapBanner: View {
    var context: ProposalScheduleContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("選択中の時間に予定があります", systemImage: "calendar.badge.exclamationmark")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)

            ForEach(context.selectedOverlaps.prefix(2)) { schedule in
                Text("\(context.roleText(for: schedule))：\(schedule.title)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ProposalScheduleLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem(title: "あなた", color: MegrumTheme.lavender)
            legendItem(title: "相手", color: MegrumTheme.sky)
            Spacer()
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

struct ProposalScheduleDayStrip: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var context: ProposalScheduleContext

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(day.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .frame(width: 62, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if schedules.isEmpty {
                    Text("予定なし")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.vertical, 5)
                } else {
                    ForEach(schedules.prefix(3)) { schedule in
                        ProposalScheduleMiniRow(schedule: schedule, isMine: context.isMine(schedule))
                    }
                    if schedules.count > 3 {
                        Text("ほか\(schedules.count - 3)件")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ProposalScheduleMiniRow: View {
    var schedule: PersonalSchedule
    var isMine: Bool

    private var color: Color {
        isMine ? MegrumTheme.lavender : MegrumTheme.sky
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(timeRangeText)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 72, alignment: .leading)

            Text(schedule.title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)

            if let placeName = schedule.placeName {
                Text(placeName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }
        }
    }

    private var timeRangeText: String {
        if schedule.allDay {
            return "終日"
        }
        let start = schedule.startAt.formatted(.dateTime.hour().minute())
        let end = schedule.endAt.formatted(.dateTime.hour().minute())
        return "\(start)-\(end)"
    }
}
