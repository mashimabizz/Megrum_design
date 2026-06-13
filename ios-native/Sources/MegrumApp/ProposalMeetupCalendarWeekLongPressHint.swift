import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarWeekLongPressHint: View {
    let isVisible: Bool
    let dayWidth: CGFloat

    @ViewBuilder
    var body: some View {
        if isVisible {
            Text("タップで待ち合わせ候補を選択")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background(MegrumTheme.ink.opacity(0.36), in: Capsule())
                .frame(width: ProposalMeetupCalendarModel.weekDayColumnsWidth(dayWidth: dayWidth), height: 38)
                .offset(
                    x: ProposalMeetupCalendarModel.timeLabelWidth,
                    y: CGFloat(ProposalMeetupCalendarModel.slotIndex(forHour: 13)) * ProposalMeetupCalendarModel.slotHeight
                )
        }
    }
}
