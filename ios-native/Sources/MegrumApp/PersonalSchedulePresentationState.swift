import Foundation

struct PersonalSchedulePresentationState: Equatable {
    var mode: TradeScheduleCalendarMode = .fiveDays
    var anchorDate: Date
    var isShowingScheduleEditor = false

    init(anchorDate: Date = Date()) {
        self.anchorDate = anchorDate
    }

    func calendarWindow(calendar: Calendar) -> TradeScheduleCalendarWindow {
        TradeScheduleCalendarWindow(mode: mode, anchorDate: anchorDate, calendar: calendar)
    }

    func visibleInterval(calendar: Calendar) -> DateInterval {
        calendarWindow(calendar: calendar).visibleInterval
    }

    func reloadKey(calendar: Calendar) -> String {
        calendarWindow(calendar: calendar).reloadKey
    }

    mutating func showScheduleEditor() {
        isShowingScheduleEditor = true
    }

    mutating func moveAnchor(by value: Int, calendar: Calendar) {
        anchorDate = calendarWindow(calendar: calendar).movedAnchor(by: value)
    }
}
