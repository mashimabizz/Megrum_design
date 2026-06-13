import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarWeekTimelineBackground: View {
    let days: [Date]
    let dayWidth: CGFloat
    let selectedDayIndex: Int

    var body: some View {
        HStack(alignment: .top, spacing: ProposalMeetupCalendarModel.daySpacing) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(width: ProposalMeetupCalendarModel.timeLabelWidth, height: ProposalMeetupCalendarModel.slotHeight * 4, alignment: .topTrailing)
                        .id(hour)
                }
            }

            ForEach(Array(days.enumerated()), id: \.offset) { index, _ in
                VStack(spacing: 0) {
                    ForEach(0..<ProposalMeetupCalendarModel.slotCount, id: \.self) { slot in
                        Rectangle()
                            .fill(slot.isMultiple(of: 4) ? MegrumTheme.sky.opacity(0.08) : Color.white.opacity(0.44))
                            .frame(width: dayWidth, height: ProposalMeetupCalendarModel.slotHeight)
                            .overlay(alignment: .topLeading) {
                                Rectangle()
                                    .fill(Color.white.opacity(slot.isMultiple(of: 4) ? 0.78 : 0.46))
                                    .frame(height: 1)
                            }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selectedDayColor(index: index).opacity(index == selectedDayIndex ? 0.34 : 0.12), lineWidth: index == selectedDayIndex ? 1.4 : 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func selectedDayColor(index: Int) -> Color {
        index == selectedDayIndex ? MegrumTheme.lavender : MegrumTheme.ink
    }
}
