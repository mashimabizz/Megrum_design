import Foundation
import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarWeekHeader: View {
    let days: [Date]
    let dayWidth: CGFloat
    let selectedDayIndex: Int
    let calendar: Calendar

    var body: some View {
        HStack(spacing: ProposalMeetupCalendarModel.daySpacing) {
            ProposalMeetupCalendarWeekHeaderTimeSpacer()

            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                ProposalMeetupCalendarWeekHeaderDayCell(
                    day: day,
                    dayWidth: dayWidth,
                    isSelected: index == selectedDayIndex,
                    calendar: calendar
                )
            }
        }
    }
}

private struct ProposalMeetupCalendarWeekHeaderTimeSpacer: View {
    var body: some View {
        Color.clear
            .frame(width: ProposalMeetupCalendarModel.timeLabelWidth, height: 1)
    }
}

private struct ProposalMeetupCalendarWeekHeaderDayCell: View {
    let day: Date
    let dayWidth: CGFloat
    let isSelected: Bool
    let calendar: Calendar

    private var dayNumberColor: Color {
        isSelected ? MegrumTheme.lavender : MegrumTheme.ink
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(ProposalMeetupCalendarModel.weekdayLabel(for: day, calendar: calendar))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day, calendar: calendar))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(dayNumberColor)
        }
        .frame(width: dayWidth)
    }
}
