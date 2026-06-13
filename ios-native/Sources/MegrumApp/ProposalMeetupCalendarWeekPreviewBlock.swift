import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarPreview: Equatable {
    var dayIndex: Int
    var startSlot: Int
    var currentSlot: Int
}

struct ProposalMeetupCalendarWeekPreviewBlock: View {
    let preview: ProposalMeetupCalendarPreview?
    let dayWidth: CGFloat

    @ViewBuilder
    var body: some View {
        if let preview {
            let range = ProposalMeetupCalendarModel.normalizedSlotRange(
                startSlot: preview.startSlot,
                currentSlot: preview.currentSlot
            )
            let height = CGFloat(max(1, range.upperBound - range.lowerBound)) * ProposalMeetupCalendarModel.slotHeight - 4
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MegrumTheme.lavender.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MegrumTheme.lavender.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                }
                .frame(width: dayWidth - 8, height: max(20, height))
                .offset(
                    x: ProposalMeetupCalendarModel.timeLabelWidth
                        + CGFloat(preview.dayIndex) * (dayWidth + ProposalMeetupCalendarModel.daySpacing)
                        + 4,
                    y: CGFloat(range.lowerBound) * ProposalMeetupCalendarModel.slotHeight + 2
                )
        }
    }
}
