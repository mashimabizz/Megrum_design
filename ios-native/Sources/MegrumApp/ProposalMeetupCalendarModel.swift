import Foundation
import SwiftUI

enum ProposalMeetupCalendarModel {
    static let visibleDayCount = 5
    static let monthColumnCount = 7
    static let slotMinutes = 15
    static let slotCount = 24 * (60 / slotMinutes)
    static let slotHeight: CGFloat = 16
    static let timeLabelWidth: CGFloat = 40
    static let daySpacing: CGFloat = 0
    static let minimumDayWidth: CGFloat = 34
    static let swipeThreshold: CGFloat = 56
    static let longPressDuration: TimeInterval = 0.28
    static let touchCancelDistance: CGFloat = 12
    static let defaultDurationSlots = 4
    static let edgeCarryRatio: CGFloat = 0.42
    static let monthHeaderHeight: CGFloat = 34
    static let monthHeaderSpacing: CGFloat = 8

    static func visibleDays(anchorDate: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<visibleDayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    static func shiftedAnchor(anchorDate: Date, direction: Int, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .day, value: direction * visibleDayCount, to: start) ?? start
    }

    static func shiftedMonthAnchor(anchorDate: Date, direction: Int, calendar: Calendar = .current) -> Date {
        let monthStart = calendar.dateInterval(of: .month, for: anchorDate)?.start
            ?? calendar.startOfDay(for: anchorDate)
        return calendar.date(byAdding: .month, value: direction, to: monthStart) ?? monthStart
    }

    static func monthTitle(anchorDate: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: anchorDate)
        return "\(components.year ?? 0)年\(components.month ?? 1)月"
    }

    static func monthGridDays(anchorDate: Date, calendar: Calendar = .current) -> [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = calendar.component(.weekday, from: month.start) - 1
        var days: [Date?] = Array(repeating: nil, count: max(0, leadingBlanks))
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % monthColumnCount != 0 {
            days.append(nil)
        }
        return days
    }

    static func slotIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let slot = hour * (60 / slotMinutes) + Int(Double(minute) / Double(slotMinutes))
        return max(0, min(slotCount - 1, slot))
    }

    static func slotIndex(forHour hour: Int) -> Int {
        max(0, min(slotCount - 1, hour * (60 / slotMinutes)))
    }

    static func normalizedSlotRange(startSlot: Int, currentSlot: Int) -> ClosedRange<Int> {
        let lower = max(0, min(startSlot, currentSlot))
        let upper = min(slotCount, max(startSlot + 1, currentSlot + 1))
        return lower...upper
    }

    static func clampedStartSlot(_ value: Int, duration: Int) -> Int {
        max(0, min(slotCount - max(duration, 1), value))
    }

    static func date(for day: Date, slot: Int, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: slot * slotMinutes, to: start) ?? start
    }

    static func shouldCreateCandidateOnBoardEnd(wasLongPressed: Bool) -> Bool {
        true
    }

    static func dayWidth(containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else {
            return minimumDayWidth
        }
        let spacingWidth = daySpacing * CGFloat(visibleDayCount - 1)
        let available = containerWidth - timeLabelWidth - spacingWidth
        return max(minimumDayWidth, floor(available / CGFloat(visibleDayCount)))
    }

    static func weekdayLabel(for date: Date, calendar: Calendar = .current) -> String {
        let labels = ["日", "月", "火", "水", "木", "金", "土"]
        return labels[max(0, min(labels.count - 1, calendar.component(.weekday, from: date) - 1))]
    }

    static func dayNumberLabel(for date: Date, calendar: Calendar = .current) -> String {
        "\(calendar.component(.day, from: date))"
    }

    static func monthDayCellWidth(containerWidth: CGFloat) -> CGFloat {
        max(42, floor(containerWidth * 0.1372))
    }

    static func monthGridWidth(containerWidth: CGFloat) -> CGFloat {
        let cellWidth = monthDayCellWidth(containerWidth: containerWidth)
        return cellWidth * CGFloat(monthColumnCount) + 4 * CGFloat(monthColumnCount - 1)
    }

    static func monthGridHeight(rowCount: Int) -> CGFloat {
        let weekdayHeight: CGFloat = 14
        let rowHeight: CGFloat = 74
        let rowSpacing: CGFloat = 4
        let rows = CGFloat(max(1, rowCount))
        let gridHeight = weekdayHeight + rowSpacing + rows * rowHeight + max(0, rows - 1) * rowSpacing
        return monthHeaderHeight + monthHeaderSpacing + gridHeight
    }

    static func weekGridWidth(dayWidth: CGFloat) -> CGFloat {
        timeLabelWidth
            + dayWidth * CGFloat(visibleDayCount)
            + daySpacing * CGFloat(visibleDayCount - 1)
    }

    static func weekDayColumnsWidth(dayWidth: CGFloat) -> CGFloat {
        dayWidth * CGFloat(visibleDayCount)
            + daySpacing * CGFloat(visibleDayCount - 1)
    }

    static func weekGridLeadingInset(containerWidth: CGFloat, dayWidth: CGFloat) -> CGFloat {
        max(0, (containerWidth - weekGridWidth(dayWidth: dayWidth)) / 2)
    }

    static func weekGridPoint(from location: CGPoint, containerWidth: CGFloat, dayWidth: CGFloat) -> CGPoint {
        CGPoint(
            x: location.x - weekGridLeadingInset(containerWidth: containerWidth, dayWidth: dayWidth),
            y: location.y
        )
    }

    static func weekCalendarPoint(
        from location: CGPoint,
        containerWidth: CGFloat,
        dayWidth: CGFloat
    ) -> (dayIndex: Int, slot: Int) {
        let gridLocation = weekGridPoint(
            from: location,
            containerWidth: containerWidth,
            dayWidth: dayWidth
        )
        let x = max(0, gridLocation.x - timeLabelWidth)
        let columnWidth = dayWidth + daySpacing
        let rawDay = Int(floor(x / max(columnWidth, 1)))
        let dayIndex = max(0, min(visibleDayCount - 1, rawDay))
        let y = max(0, gridLocation.y)
        let rawSlot = Int(floor(y / slotHeight))
        let slot = max(0, min(slotCount - 1, rawSlot))
        return (dayIndex, slot)
    }

    static func clampedWeekDragOffset(_ translationWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        let maxDrag = max(1, containerWidth) * edgeCarryRatio
        return max(-maxDrag, min(maxDrag, translationWidth))
    }

    static func shouldShiftWeek(translationWidth: CGFloat, translationHeight: CGFloat, containerWidth: CGFloat) -> Bool {
        let threshold = min(96, max(44, containerWidth * 0.22))
        return abs(translationWidth) >= threshold
            && abs(translationWidth) >= abs(translationHeight) * 1.25
    }
}

extension ProposalMeetupCandidateDraft {
    func applyingCalendarRange(
        day: Date,
        startSlot: Int,
        endSlot: Int,
        calendar: Calendar = .current
    ) -> ProposalMeetupCandidateDraft {
        var draft = self
        draft.startAt = ProposalMeetupCalendarModel.date(for: day, slot: startSlot, calendar: calendar)
        draft.endAt = ProposalMeetupCalendarModel.date(for: day, slot: endSlot, calendar: calendar)
        return draft
    }
}

enum ProposalMeetupCalendarDisplayMode: String, CaseIterable, Identifiable, Equatable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            "週"
        case .month:
            "月"
        }
    }
}
