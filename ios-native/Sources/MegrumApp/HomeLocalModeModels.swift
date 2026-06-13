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
        if let fallbackPrefecture, !fallbackPrefecture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

struct HomeLocalCarryingCandidate: Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var subtitle: String
    var quantity: Int
    var imageURL: URL?

    static func candidates(from items: [GoodsItem], viewerID: UUID?) -> [HomeLocalCarryingCandidate] {
        var seen = Set<UUID>()
        return items.compactMap { item in
            if let viewerID, item.ownerID != viewerID {
                return nil
            }
            guard seen.insert(item.id).inserted else {
                return nil
            }
            return HomeLocalCarryingCandidate(item: item)
        }
    }

    static func sourceItems(
        inventory: [GoodsItem],
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem]
    ) -> [GoodsItem] {
        guard !inventory.isEmpty else {
            return matchedItems + possibleItems
        }
        return inventory
    }

    init(item: GoodsItem) {
        self.id = item.id
        self.title = item.title
        self.subtitle = Self.subtitle(for: item)
        self.quantity = item.quantity
        self.imageURL = item.imageURL
    }

    private static func subtitle(for item: GoodsItem) -> String {
        let tagLine = item.tags.prefix(2).map(\.name).joined(separator: " / ")
        if !tagLine.isEmpty {
            return tagLine
        }
        if item.quantity > 1 {
            return "\(item.quantity)点"
        }
        return "譲る候補"
    }
}

struct HomeLocalCarryingSummary: Equatable {
    var selectedCount: Int
    var availableCount: Int
    var selectedTitles: [String]

    init(candidates: [HomeLocalCarryingCandidate], selectedIDs: Set<UUID>) {
        let selected = candidates.filter { selectedIDs.contains($0.id) }
        self.selectedCount = selected.count
        self.availableCount = candidates.count
        self.selectedTitles = selected.prefix(2).map(\.title)
    }

    var countText: String {
        if availableCount == 0 {
            return "持参 0件"
        }
        return "持参 \(selectedCount)/\(availableCount)件"
    }

    var titleText: String {
        if selectedTitles.isEmpty {
            return availableCount == 0 ? "譲る候補なし" : "持参グッズ未選択"
        }
        return selectedTitles.joined(separator: "、")
    }
}

enum HomeLocalCarryingSelectionCodec {
    static func decode(_ value: String) -> Set<UUID> {
        Set(
            value
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }
        )
    }

    static func encode(_ ids: Set<UUID>) -> String {
        ids
            .map { $0.uuidString.lowercased() }
            .sorted()
            .joined(separator: ",")
    }
}

enum HomeLocalLocationLabel {
    static let resolvingText = "住所を確認中"
    static let unresolvedText = "現在地を取得済み"

    static func coordinateText(latitude: Double, longitude: Double) -> String {
        unresolvedText
    }

    static func coordinateText(_ coordinate: MegrumLocationCoordinate) -> String {
        coordinateText(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func isCoordinateBackedText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == resolvingText || trimmed == unresolvedText {
            return true
        }
        return coordinate(in: trimmed) != nil
    }

    static func coordinate(in text: String) -> MegrumLocationCoordinate? {
        let normalized = text
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "、", with: ",")
            .replacingOccurrences(of: "：", with: ":")
        let commaSeparatedPattern = #"-?\d{1,2}(?:\.\d+)?\s*,\s*-?\d{1,3}(?:\.\d+)?"#
        if let range = normalized.range(of: commaSeparatedPattern, options: .regularExpression) {
            let parts = normalized[range]
                .split(separator: ",", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2,
               let latitude = Double(parts[0]),
               let longitude = Double(parts[1]),
               HomeLocalCoordinateStorageCodec.isValid(latitude: latitude, longitude: longitude) {
                return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
            }
        }

        guard normalized.localizedCaseInsensitiveContains("lat")
            || normalized.localizedCaseInsensitiveContains("lng")
            || normalized.contains("緯度")
            || normalized.contains("経度")
        else {
            return nil
        }
        let decimalPattern = #"-?\d{1,3}\.\d+"#
        let matches = normalized.matches(forRegularExpression: decimalPattern)
        guard matches.count >= 2,
              let latitude = Double(matches[0]),
              let longitude = Double(matches[1]),
              HomeLocalCoordinateStorageCodec.isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }
}

enum HomeLocalCoordinateStorageCodec {
    static func decode(latitudeText: String, longitudeText: String) -> MegrumLocationCoordinate? {
        guard let latitude = Double(latitudeText),
              let longitude = Double(longitudeText),
              isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }

    static func latitudeText(_ coordinate: MegrumLocationCoordinate?) -> String {
        coordinate.map { String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), $0.latitude) } ?? ""
    }

    static func longitudeText(_ coordinate: MegrumLocationCoordinate?) -> String {
        coordinate.map { String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), $0.longitude) } ?? ""
    }

    static func isValid(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}

private extension String {
    func matches(forRegularExpression pattern: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let fullRange = NSRange(startIndex..<endIndex, in: self)
        return expression.matches(in: self, range: fullRange).compactMap { match in
            Range(match.range, in: self).map { String(self[$0]) }
        }
    }
}
