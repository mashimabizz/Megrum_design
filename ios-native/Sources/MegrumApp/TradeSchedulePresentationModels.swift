import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeScheduleCalendarMode: String, CaseIterable, Identifiable {
    case fiveDays
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fiveDays:
            "週"
        case .month:
            "月"
        }
    }
}

struct TradeScheduleCalendarWindow {
    var mode: TradeScheduleCalendarMode
    var anchorDate: Date
    var calendar: Calendar

    var visibleInterval: DateInterval {
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

    var reloadKey: String {
        "\(mode.rawValue)-\(Int(visibleInterval.start.timeIntervalSince1970))"
    }

    var fiveVisibleDays: [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    var monthTitle: String {
        anchorDate.formatted(.dateTime.year().month(.wide))
    }

    func schedules(on day: Date, from schedules: [PersonalSchedule]) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { $0.overlaps(start: start, end: end) }
    }

    func movedAnchor(by value: Int) -> Date {
        let component: Calendar.Component = mode == .month ? .month : .day
        return calendar.date(byAdding: component, value: value, to: anchorDate) ?? anchorDate
    }
}

enum TradePreviewThumbnailStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("カリナ") {
            return "K"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch abs(item.id.hashValue) % 3 {
        case 0:
            return MegrumTheme.lavender.opacity(0.62)
        case 1:
            return MegrumTheme.sky.opacity(0.72)
        default:
            return MegrumTheme.pink.opacity(0.62)
        }
    }
}
