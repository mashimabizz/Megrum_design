import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalMeetupCalendarEditor: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var anchorDate: Date
    var scheduleContext: ProposalScheduleContext
    var onSelectDraft: (Int) -> Void
    var onShiftWeek: (Int) -> Void
    var onSelectMonthDay: (Date) -> Void
    var onShiftMonth: (Int) -> Void
    var onCreateDraft: (Date, Int, Int) -> Void
    var onUpdateDraft: (Int, Date, Int, Int) -> Void
    var onRemoveDraft: (Int) -> Void
    var onOpenPlaceEntry: (Int) -> Void

    @State private var displayState = ProposalMeetupCalendarDisplayState()

    private let calendar = Calendar.current

    var body: some View {
        ProposalMeetupCalendarCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if displayState.showsWeekTitle {
                        Text(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchorDate, calendar: calendar))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                    }

                    Spacer(minLength: 0)
                    ProposalMeetupCalendarModeToggle(selection: $displayState.displayMode)
                }

                switch displayState.displayMode {
                case .week:
                    ProposalMeetupCalendarWeekEditor(
                        drafts: drafts,
                        selectedIndex: selectedIndex,
                        anchorDate: anchorDate,
                        onSelectDraft: onSelectDraft,
                        onShiftWeek: onShiftWeek,
                        onCreateDraft: onCreateDraft,
                        onUpdateDraft: onUpdateDraft,
                        onRemoveDraft: onRemoveDraft,
                        onOpenPlaceEntry: onOpenPlaceEntry
                    )
                case .month:
                    ProposalMeetupMonthCalendar(
                        anchorDate: anchorDate,
                        scheduleContext: scheduleContext,
                        onShiftMonth: onShiftMonth,
                        onSelectDay: { day in
                            onSelectMonthDay(day)
                            displayState.showWeek()
                        }
                    )
                }
            }
        }
    }
}
