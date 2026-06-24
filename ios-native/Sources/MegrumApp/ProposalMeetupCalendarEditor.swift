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

    @State private var displayMode: ProposalMeetupCalendarDisplayMode = Self.initialDisplayMode()

    private let calendar = Calendar.current

    private static func initialDisplayMode(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ProposalMeetupCalendarDisplayMode {
        VisualQAPreviewMode.initialScreen(environment: environment) == .proposalMeetupMonth ? .month : .week
    }

    var body: some View {
        ProposalMeetupCalendarCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if displayMode == .week {
                        Text(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchorDate, calendar: calendar))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                    }

                    Spacer(minLength: 0)
                    ProposalMeetupCalendarModeToggle(selection: $displayMode)
                }

                switch displayMode {
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
                            displayMode = .week
                        }
                    )
                }
            }
        }
    }
}
