import Foundation
import MegrumCore

struct ProposalMeetupMapDraft {
    static let fallbackPlaceName = "地図で選択した場所"

    static func coordinateValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func coordinateText(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    static func coordinate(latitudeText: String, longitudeText: String) -> MegrumLocationCoordinate? {
        guard
            let latitude = coordinateValue(from: latitudeText),
            let longitude = coordinateValue(from: longitudeText),
            isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }

    static func isValid(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}

struct ProposalMeetupCandidateDraft: Identifiable, Equatable {
    static let maxCandidates = 5
    static let defaultDuration: TimeInterval = 30 * 60

    var id: UUID
    var startAt: Date
    var endAt: Date
    var placeName: String
    var latitudeText: String
    var longitudeText: String

    init(
        id: UUID = UUID(),
        startAt: Date = Date(),
        endAt: Date? = nil,
        placeName: String = "",
        latitudeText: String = "",
        longitudeText: String = ""
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt ?? startAt.addingTimeInterval(Self.defaultDuration)
        self.placeName = placeName
        self.latitudeText = latitudeText
        self.longitudeText = longitudeText
    }

    var meetupInput: ProposalMeetupInput? {
        guard let coordinate = ProposalMeetupMapDraft.coordinate(
            latitudeText: latitudeText,
            longitudeText: longitudeText
        ) else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: startAt,
            endAt: endAt,
            placeName: placeName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return input.isValid ? input : nil
    }

    var normalizedPlaceName: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        meetupInput != nil
    }

    func summary(index: Int) -> String {
        let prefix = "候補\(index + 1)"
        let dateText = Self.dateText(startAt)
        if normalizedPlaceName.isEmpty {
            return "\(prefix) / \(dateText)"
        }
        return "\(prefix) / \(dateText) / \(normalizedPlaceName)"
    }

    func applyingCurrentLocation(_ coordinate: MegrumLocationCoordinate) -> Self {
        var draft = self
        if draft.normalizedPlaceName.isEmpty {
            draft.placeName = "現在地"
        }
        if draft.latitudeText.isBlank {
            draft.latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        }
        if draft.longitudeText.isBlank {
            draft.longitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        }
        return draft
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .hour()
                .minute()
        )
    }
}

enum ProposalScheduleCalendarMode: String, CaseIterable, Identifiable, Equatable {
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

struct ProposalScheduleContext: Equatable {
    var schedules: [PersonalSchedule]
    var viewerID: UUID?
    var partnerID: UUID
    var selectedInterval: DateInterval

    init(
        schedules: [PersonalSchedule],
        viewerID: UUID?,
        partnerID: UUID,
        selectedStartAt: Date,
        selectedEndAt: Date
    ) {
        self.viewerID = viewerID
        self.partnerID = partnerID
        if selectedStartAt < selectedEndAt {
            self.selectedInterval = DateInterval(start: selectedStartAt, end: selectedEndAt)
        } else {
            self.selectedInterval = DateInterval(start: selectedStartAt, duration: 60)
        }

        var seenIDs: Set<UUID> = []
        self.schedules = schedules
            .filter { schedule in
                schedule.userID == viewerID || schedule.userID == partnerID
            }
            .filter { schedule in
                seenIDs.insert(schedule.id).inserted
            }
            .sorted { left, right in
                if left.startAt == right.startAt {
                    return left.title < right.title
                }
                return left.startAt < right.startAt
            }
    }

    var selectedOverlaps: [PersonalSchedule] {
        schedules.filter { schedule in
            schedule.overlaps(start: selectedInterval.start, end: selectedInterval.end)
        }
    }

    func roleText(for schedule: PersonalSchedule) -> String {
        schedule.userID == viewerID ? "あなた" : "相手"
    }

    func isMine(_ schedule: PersonalSchedule) -> Bool {
        schedule.userID == viewerID
    }

    func visibleDays(anchorDate: Date, mode: ProposalScheduleCalendarMode, calendar: Calendar = .current) -> [Date] {
        switch mode {
        case .fiveDays:
            let start = calendar.startOfDay(for: anchorDate)
            return (0..<5).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: start)
            }
        case .month:
            guard let month = calendar.dateInterval(of: .month, for: anchorDate),
                  let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
            else {
                return []
            }
            return dayRange.compactMap { day in
                calendar.date(byAdding: .day, value: day - 1, to: month.start)
            }
        }
    }

    func schedules(on day: Date, calendar: Calendar = .current) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { schedule in
            schedule.overlaps(start: start, end: end)
        }
    }

    var placeSuggestions: [String] {
        var seen: Set<String> = []
        return schedules.compactMap { schedule in
            guard let placeName = schedule.placeName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !placeName.isEmpty,
                  seen.insert(placeName).inserted
            else {
                return nil
            }
            return placeName
        }
    }
}
