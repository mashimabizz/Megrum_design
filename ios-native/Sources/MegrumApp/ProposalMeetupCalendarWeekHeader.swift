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
            Color.clear
                .frame(width: ProposalMeetupCalendarModel.timeLabelWidth, height: 1)
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 2) {
                    Text(ProposalMeetupCalendarModel.weekdayLabel(for: day, calendar: calendar))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    Text(ProposalMeetupCalendarModel.dayNumberLabel(for: day, calendar: calendar))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(selectedDayColor(index: index))
                }
                .frame(width: dayWidth)
            }
        }
    }

    private func selectedDayColor(index: Int) -> Color {
        index == selectedDayIndex ? MegrumTheme.lavender : MegrumTheme.ink
    }
}
