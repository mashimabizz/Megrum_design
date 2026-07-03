import Foundation

struct ProposalScheduleBackgroundPresentationState: Equatable {
    var mode: ProposalScheduleCalendarMode = .fiveDays

    func visibleDays(
        context: ProposalScheduleContext,
        anchorDate: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        context.visibleDays(anchorDate: anchorDate, mode: mode, calendar: calendar)
    }
}
