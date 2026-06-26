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
            ProposalMeetupCalendarWeekPreviewContent(
                preview: preview,
                dayWidth: dayWidth
            )
        }
    }
}

private struct ProposalMeetupCalendarWeekPreviewContent: View {
    let preview: ProposalMeetupCalendarPreview
    let dayWidth: CGFloat

    private var slotRange: ClosedRange<Int> {
        ProposalMeetupCalendarModel.normalizedSlotRange(
            startSlot: preview.startSlot,
            currentSlot: preview.currentSlot
        )
    }

    private var previewHeight: CGFloat {
        CGFloat(max(1, slotRange.upperBound - slotRange.lowerBound)) * ProposalMeetupCalendarModel.slotHeight - 4
    }

    private var previewOffset: CGSize {
        CGSize(
            width: ProposalMeetupCalendarModel.timeLabelWidth
                + CGFloat(preview.dayIndex) * (dayWidth + ProposalMeetupCalendarModel.daySpacing)
                + 4,
            height: CGFloat(slotRange.lowerBound) * ProposalMeetupCalendarModel.slotHeight + 2
        )
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.22))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MegrumTheme.lavender.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            }
            .frame(width: dayWidth - 8, height: max(20, previewHeight))
            .offset(previewOffset)
    }
}
