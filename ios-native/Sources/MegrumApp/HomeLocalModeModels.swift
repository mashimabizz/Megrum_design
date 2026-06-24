import Foundation
import MegrumCore

public struct HomeLocalActivitySettings: Equatable, Sendable {
    var activityWindowID: UUID?
    var isEnabled: Bool
    var venue: String
    var coordinate: MegrumLocationCoordinate?
    var startedAt: Date?
    var durationMinutes: Int
    var radiusMeters: Int
    var selectedCarryingIDs: Set<UUID>

    static let defaultDurationMinutes = 120
    static let defaultRadiusMeters = 500
    static let durationOptions = [60, 120, 180, 360]
    static let radiusOptions = [300, 500, 1_000, 2_000]

    init(
        activityWindowID: UUID? = nil,
        isEnabled: Bool,
        venue: String,
        coordinate: MegrumLocationCoordinate? = nil,
        startedAt: Date?,
        durationMinutes: Int,
        radiusMeters: Int,
        selectedCarryingIDs: Set<UUID>
    ) {
        self.activityWindowID = activityWindowID
        self.isEnabled = isEnabled
        self.venue = venue
        self.coordinate = coordinate
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.radiusMeters = radiusMeters
        self.selectedCarryingIDs = selectedCarryingIDs
    }

    var normalizedVenue: String {
        venue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDurationMinutes: Int {
        Self.normalizedDurationMinutes(durationMinutes)
    }

    var normalizedRadiusMeters: Int {
        Self.normalizedRadiusMeters(radiusMeters)
    }

    static func normalizedDurationMinutes(_ minutes: Int) -> Int {
        durationOptions.contains(minutes) ? minutes : defaultDurationMinutes
    }

    static func normalizedRadiusMeters(_ meters: Int) -> Int {
        radiusOptions.contains(meters) ? meters : defaultRadiusMeters
    }

    func normalizedForPersistence(now: Date = .now, fallbackActivityWindowID: UUID? = nil) -> HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: activityWindowID ?? fallbackActivityWindowID,
            isEnabled: isEnabled,
            venue: normalizedVenue,
            coordinate: coordinate,
            startedAt: isEnabled ? (startedAt ?? now) : startedAt,
            durationMinutes: normalizedDurationMinutes,
            radiusMeters: normalizedRadiusMeters,
            selectedCarryingIDs: selectedCarryingIDs
        )
    }

    func replacingSelectedCarryingIDs(_ selectedIDs: Set<UUID>) -> HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: activityWindowID,
            isEnabled: isEnabled,
            venue: venue,
            coordinate: coordinate,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            radiusMeters: radiusMeters,
            selectedCarryingIDs: selectedIDs
        )
    }

    func replacingCoordinate(_ coordinate: MegrumLocationCoordinate?) -> HomeLocalActivitySettings {
        HomeLocalActivitySettings(
            activityWindowID: activityWindowID,
            isEnabled: isEnabled,
            venue: venue,
            coordinate: coordinate,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            radiusMeters: radiusMeters,
            selectedCarryingIDs: selectedCarryingIDs
        )
    }

    func displayVenue(fallbackPrefecture: String?) -> String {
        if !normalizedVenue.isEmpty,
           !HomeLocalLocationLabel.isCoordinateBackedText(normalizedVenue) {
            return normalizedVenue
        }
        if coordinate != nil || HomeLocalLocationLabel.coordinate(in: normalizedVenue) != nil {
            return HomeLocalLocationLabel.unresolvedText
        }
        if let fallbackPrefecture, !fallbackPrefecture.isBlank {
            return "\(fallbackPrefecture)周辺"
        }
        return "現在地未設定"
    }

    func status(now: Date = .now) -> HomeLocalActivityStatus {
        guard isEnabled else {
            return .off
        }
        let start = startedAt ?? now
        let end = endDate(now: now)
        if now < start {
            return .scheduled
        }
        if now <= end {
            return .live
        }
        return .expired
    }

    func endDate(now: Date = .now) -> Date {
        let start = startedAt ?? now
        return start.addingTimeInterval(TimeInterval(max(30, durationMinutes) * 60))
    }

    func timeWindowText(now: Date = .now, calendar: Calendar = .current) -> String {
        let start = startedAt ?? now
        return HomeLocalActivityFormatter.timeRangeText(start: start, end: endDate(now: now), calendar: calendar)
    }

    var radiusText: String {
        HomeLocalActivityFormatter.radiusText(radiusMeters)
    }

    func carryingSummary(from candidates: [HomeLocalCarryingCandidate]) -> HomeLocalCarryingSummary {
        HomeLocalCarryingSummary(candidates: candidates, selectedIDs: selectedCarryingIDs)
    }

    func publicPreview(
        now: Date = .now,
        fallbackPrefecture: String?,
        carryingSummary: HomeLocalCarryingSummary
    ) -> HomeLocalPublicPreview {
        let status = status(now: now)
        let venueText = displayVenue(fallbackPrefecture: fallbackPrefecture)
        let carryingText = carryingSummary.availableCount == 0 ? "持参候補なし" : carryingSummary.countText

        switch status {
        case .off:
            return HomeLocalPublicPreview(
                isVisible: false,
                badgeText: "未公開",
                title: "相手には表示されません",
                detail: "ONにすると、場所・時間・持参グッズが現地マッチに使われます。"
            )
        case .scheduled:
            return HomeLocalPublicPreview(
                isVisible: true,
                badgeText: "予定公開",
                title: "\(venueText)で予定として表示",
                detail: "\(timeWindowText(now: now))・\(radiusText)・\(carryingText)"
            )
        case .live:
            return HomeLocalPublicPreview(
                isVisible: true,
                badgeText: "相手に表示中",
                title: "\(venueText)で現地交換中",
                detail: "\(timeWindowText(now: now))・\(radiusText)・\(carryingText)"
            )
        case .expired:
            return HomeLocalPublicPreview(
                isVisible: false,
                badgeText: "更新が必要",
                title: "時間切れのため相手側から外れます",
                detail: "再度ONにすると、いまの場所が現地マッチに反映されます。"
            )
        }
    }
}

enum HomeLocalActivityStatus: Equatable {
    case off
    case scheduled
    case live
    case expired

    var label: String {
        switch self {
        case .off:
            "OFF"
        case .scheduled:
            "予定"
        case .live:
            "LIVE"
        case .expired:
            "時間切れ"
        }
    }

    var isLive: Bool {
        self == .live
    }

    var isVisibleToOthers: Bool {
        self == .scheduled || self == .live
    }
}

struct HomeLocalPublicPreview: Equatable {
    var isVisible: Bool
    var badgeText: String
    var title: String
    var detail: String
}

enum HomeLocalActivityFormatter {
    static func radiusText(_ meters: Int) -> String {
        if meters >= 1_000, meters.isMultiple(of: 1_000) {
            return "\(meters / 1_000)km"
        }
        return "\(meters)m"
    }

    static func timeRangeText(start: Date, end: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: start))-\(formatter.string(from: end))"
    }
}
