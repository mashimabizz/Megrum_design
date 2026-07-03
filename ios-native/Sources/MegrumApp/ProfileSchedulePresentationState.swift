import Foundation
import MegrumCore

struct ProfileSchedulePresentationState: Equatable {
    var mode: TradeScheduleCalendarMode = .fiveDays
    var anchorDate: Date

    init(anchorDate: Date = Date()) {
        self.anchorDate = anchorDate
    }

    func visibleInterval(calendar: Calendar) -> DateInterval {
        switch mode {
        case .fiveDays:
            let start = calendar.startOfDay(for: anchorDate)
            let end = calendar.date(byAdding: .day, value: 5, to: start) ?? start.addingTimeInterval(86_400 * 5)
            return DateInterval(start: start, end: end)
        case .month:
            return calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: calendar.startOfDay(for: anchorDate), duration: 86_400 * 31)
        }
    }

    func reloadKey(userID: UUID, calendar: Calendar) -> String {
        let intervalStart = visibleInterval(calendar: calendar).start
        return "\(userID.uuidString)-\(mode.rawValue)-\(Int(intervalStart.timeIntervalSince1970))"
    }

    func fiveVisibleDays(calendar: Calendar) -> [Date] {
        let interval = visibleInterval(calendar: calendar)
        return (0..<5).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    func monthDays(calendar: Calendar) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchorDate) else {
            return []
        }
        let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        return (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monthInterval.start)
        }
    }

    func schedules(on day: Date, from schedules: [PersonalSchedule], calendar: Calendar) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { $0.overlaps(start: start, end: end) }
    }

    mutating func moveAnchor(by value: Int, calendar: Calendar) {
        if let next = calendar.date(byAdding: .day, value: value, to: anchorDate) {
            anchorDate = next
        }
    }
}
