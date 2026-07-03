import Foundation
import MegrumCore

struct ScheduleEditorDraftState: Equatable {
    var title = ""
    var placeName = ""
    var startAt: Date
    var endAt: Date
    var allDay = false
    var note = ""

    init(defaultDate: Date) {
        let start = Self.defaultStartDate(defaultDate)
        self.startAt = start
        self.endAt = start.addingTimeInterval(3_600)
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func canSave(isCreatingSchedule: Bool) -> Bool {
        !trimmedTitle.isEmpty && startAt < endAt && !isCreatingSchedule
    }

    mutating func adjustEndAfterStartChange() {
        guard endAt <= startAt else {
            return
        }
        endAt = startAt.addingTimeInterval(allDay ? 86_400 : 3_600)
    }

    mutating func setAllDay(_ isAllDay: Bool, calendar: Calendar = .current) {
        allDay = isAllDay
        if isAllDay {
            let day = calendar.startOfDay(for: startAt)
            startAt = day
            endAt = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        } else if endAt <= startAt {
            endAt = startAt.addingTimeInterval(3_600)
        }
    }

    func makeInput() -> PersonalScheduleCreateInput {
        PersonalScheduleCreateInput(
            title: title,
            placeName: placeName,
            startAt: startAt,
            endAt: endAt,
            allDay: allDay,
            note: note
        )
    }

    static func defaultStartDate(
        _ date: Date,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Date {
        if calendar.isDate(date, inSameDayAs: now) {
            let minute = calendar.component(.minute, from: now)
            let minutesToAdd = minute < 30 ? 30 - minute : 60 - minute
            let next = calendar.date(byAdding: .minute, value: minutesToAdd, to: now)
                ?? now.addingTimeInterval(1_800)
            return calendar.dateInterval(of: .minute, for: next)?.start ?? next
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}
