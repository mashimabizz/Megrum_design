import Foundation

public struct PersonalSchedule: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        id: UUID,
        userID: UUID,
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var durationInterval: DateInterval {
        if endAt > startAt {
            return DateInterval(start: startAt, end: endAt)
        }
        return DateInterval(start: startAt, duration: 60)
    }

    public func overlaps(start: Date, end: Date) -> Bool {
        startAt < end && endAt > start
    }
}

public struct PersonalScheduleCreateInput: Equatable, Sendable {
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var normalizedPlaceName: String? {
        placeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var normalizedNote: String? {
        note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var isValid: Bool {
        !normalizedTitle.isEmpty && startAt < endAt
    }
}
