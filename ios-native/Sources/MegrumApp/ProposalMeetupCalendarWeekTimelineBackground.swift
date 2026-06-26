import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarWeekTimelineBackground: View {
    let days: [Date]
    let dayWidth: CGFloat
    let selectedDayIndex: Int

    var body: some View {
        HStack(alignment: .top, spacing: ProposalMeetupCalendarModel.daySpacing) {
            ProposalMeetupCalendarWeekTimeLabelColumn()

            ForEach(Array(days.enumerated()), id: \.offset) { index, _ in
                ProposalMeetupCalendarWeekDayTimelineColumn(
                    dayWidth: dayWidth,
                    isSelected: index == selectedDayIndex
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProposalMeetupCalendarWeekTimeLabelColumn: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                ProposalMeetupCalendarWeekTimeLabel(hour: hour)
                    .id(hour)
            }
        }
    }
}

private struct ProposalMeetupCalendarWeekTimeLabel: View {
    let hour: Int

    var body: some View {
        Text(String(format: "%02d:00", hour))
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(
                width: ProposalMeetupCalendarModel.timeLabelWidth,
                height: ProposalMeetupCalendarModel.slotHeight * 4,
                alignment: .topTrailing
            )
    }
}

private struct ProposalMeetupCalendarWeekDayTimelineColumn: View {
    let dayWidth: CGFloat
    let isSelected: Bool

    private var strokeColor: Color {
        isSelected ? MegrumTheme.lavender.opacity(0.34) : MegrumTheme.ink.opacity(0.12)
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1.4 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<ProposalMeetupCalendarModel.slotCount, id: \.self) { slot in
                ProposalMeetupCalendarWeekTimelineSlot(
                    slot: slot,
                    dayWidth: dayWidth
                )
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(strokeColor, lineWidth: strokeWidth)
        }
    }
}

private struct ProposalMeetupCalendarWeekTimelineSlot: View {
    let slot: Int
    let dayWidth: CGFloat

    private var isHourBoundary: Bool {
        slot.isMultiple(of: 4)
    }

    var body: some View {
        Rectangle()
            .fill(isHourBoundary ? MegrumTheme.sky.opacity(0.08) : Color.white.opacity(0.44))
            .frame(width: dayWidth, height: ProposalMeetupCalendarModel.slotHeight)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.white.opacity(isHourBoundary ? 0.78 : 0.46))
                    .frame(height: 1)
            }
    }
}
