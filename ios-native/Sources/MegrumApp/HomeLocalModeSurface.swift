import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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

struct HomeLocalModeSurface: View {
    var viewer: UserProfile?
    var settings: HomeLocalActivitySettings
    var carryingCandidates: [HomeLocalCarryingCandidate]
    var isLoadingSettings = false
    var isSavingSettings = false
    var onEdit: () -> Void

    var body: some View {
        let now = Date()
        let status = settings.status(now: now)
        let carryingSummary = settings.carryingSummary(from: carryingCandidates)
        let publicPreview = settings.publicPreview(
            now: now,
            fallbackPrefecture: viewer?.prefecture,
            carryingSummary: carryingSummary
        )

        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    HomeLocalStatusBadge(status: status)
                    Spacer(minLength: 12)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("現地交換")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(settings.displayVenue(fallbackPrefecture: viewer?.prefecture))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    HomeLocalMetricChip(systemImage: "clock", text: settings.timeWindowText(now: now))
                    HomeLocalMetricChip(systemImage: "scope", text: settings.radiusText)
                    HomeLocalMetricChip(systemImage: "bag", text: carryingSummary.countText)
                }

                HomeLocalPublicPreviewRow(preview: publicPreview)

                if isLoadingSettings || isSavingSettings {
                    HomeLocalSyncStatusRow(isLoading: isLoadingSettings, isSaving: isSavingSettings)
                }

                if settings.isEnabled {
                    Text(carryingSummary.titleText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        status.isLive ? MegrumTheme.lavender.opacity(0.5) : Color.white.opacity(0.7),
                        lineWidth: 1
                    )
            }
            .shadow(color: MegrumTheme.ink.opacity(status.isLive ? 0.13 : 0.07), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("現地交換モード")
        .accessibilityValue("\(status.label)、\(publicPreview.title)、\(settings.timeWindowText(now: Date()))、\(settings.radiusText)、\(carryingSummary.countText)")
    }
}

private struct HomeLocalStatusBadge: View {
    var status: HomeLocalActivityStatus

    var body: some View {
        Label {
            Text(status.label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        } icon: {
            Image(systemName: status.isLive ? "location.circle.fill" : "location.circle")
                .font(.system(size: 13, weight: .heavy))
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(status.isLive ? Color.white : MegrumTheme.lavender)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.isLive ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.12), in: Capsule())
    }
}

private struct HomeLocalPublicPreviewRow: View {
    var preview: HomeLocalPublicPreview

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: preview.isVisible ? "eye.fill" : "eye.slash")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(preview.badgeText)
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)

                    Text(preview.title)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                }

                Text(preview.detail)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HomeLocalPublicPreviewListRow: View {
    var preview: HomeLocalPublicPreview

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(preview.title)
                    .font(.body.weight(.semibold))
                Text(preview.detail)
                    .font(.caption)
                    .foregroundStyle(MegrumTheme.muted)
            }
        } icon: {
            Image(systemName: preview.isVisible ? "eye.fill" : "eye.slash")
                .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preview.badgeText)、\(preview.title)、\(preview.detail)")
    }
}

private struct HomeLocalSyncStatusRow: View {
    var isLoading: Bool
    var isSaving: Bool

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.72)
            Text(isSaving ? "現地交換モードを保存中" : "現地交換モードを読み込み中")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.5), in: Capsule())
    }
}

private struct HomeLocalMetricChip: View {
    var systemImage: String
    var text: String

    var body: some View {
        Label {
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(MegrumTheme.ink.opacity(0.82))
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.68), in: Capsule())
    }
}

struct HomeGroomEntrySummary: Equatable {
    var groomCount: Int
    var badgeText: String
    var title: String
    var detail: String

    init(groomCount: Int, localStatus: HomeLocalActivityStatus, venue: String) {
        self.groomCount = groomCount
        self.badgeText = groomCount == 0 ? "0件" : "\(groomCount)件"

        if groomCount == 0 {
            self.title = "近くのグルームはまだありません"
            self.detail = "現地の写真や列状況は、めぐりタブから投稿できます。"
        } else if localStatus.isVisibleToOthers {
            self.title = "近くのグルームも確認"
            self.detail = "\(venue)周辺の写真や現地状況を見ながら、交換相手を探せます。"
        } else {
            self.title = "グルームで現地状況を見る"
            self.detail = "現地交換モードをONにすると、周辺の写真とマッチ確認がつながります。"
        }
    }
}

struct HomeGroomEntrySurface: View {
    var summary: HomeGroomEntrySummary
    var onOpen: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MegrumTheme.sky.opacity(0.22))
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text("グルーム")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(summary.badgeText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text(summary.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary.detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let onOpen {
                Button(action: onOpen) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.74), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("グルームを開く")
            } else {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel("めぐりタブで確認")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.68), lineWidth: 1)
        }
    }
}

struct HomeLocalModeSettingsSheet: View {
    var viewer: UserProfile?
    var settings: HomeLocalActivitySettings
    var carryingCandidates: [HomeLocalCarryingCandidate]
    var onSave: (HomeLocalActivitySettings) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationState = MegrumLocationState()
    @State private var draft: HomeLocalActivityDraft

    init(
        viewer: UserProfile?,
        settings: HomeLocalActivitySettings,
        carryingCandidates: [HomeLocalCarryingCandidate],
        onSave: @escaping (HomeLocalActivitySettings) -> Void
    ) {
        self.viewer = viewer
        self.settings = settings
        self.carryingCandidates = carryingCandidates
        self.onSave = onSave
        _draft = State(initialValue: HomeLocalActivityDraft(settings: settings, fallbackPrefecture: viewer?.prefecture))
    }

    var body: some View {
        let previewSettings = draft.settings(savedAt: .now, original: settings)
        let previewSummary = previewSettings.carryingSummary(from: carryingCandidates)
        let publicPreview = previewSettings.publicPreview(
            fallbackPrefecture: viewer?.prefecture,
            carryingSummary: previewSummary
        )

        NavigationStack {
            Form {
                Section {
                    Toggle("現地交換モード", isOn: $draft.isEnabled)
                }

                Section {
                    LabeledContent("反映先", value: settings.activityWindowID == nil ? "現在地を新しく反映" : "現在地を上書き")
                    HomeLocalPublicPreviewListRow(preview: publicPreview)
                } header: {
                    Text("現在地の表示")
                } footer: {
                    Text("ONの間は、現在地・有効時間・半径・持参グッズが現地マッチに使われます。")
                }

                Section("現在地") {
                    TextField("建物名・会場・駅・エリア", text: $draft.venue)

                    Button {
                        locationState.requestCurrentLocation()
                    } label: {
                        Label(locationButtonTitle, systemImage: "location")
                    }
                    .disabled(locationState.isRequestingLocation)

                    if let locationErrorMessage = locationState.locationErrorMessage {
                        Text(locationErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let coordinate = draft.coordinate {
                        LabeledContent(
                            "取得した場所",
                            value: locationState.resolvedLocationLabel
                                ?? (locationState.isResolvingLocationLabel ? HomeLocalLocationLabel.resolvingText : HomeLocalLocationLabel.coordinateText(coordinate))
                        )
                    }
                }

                Section("有効時間") {
                    Picker("有効時間", selection: $draft.durationMinutes) {
                        ForEach(HomeLocalActivitySettings.durationOptions, id: \.self) { minutes in
                            Text(durationLabel(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("半径") {
                    Picker("半径", selection: $draft.radiusMeters) {
                        ForEach(HomeLocalActivitySettings.radiusOptions, id: \.self) { meters in
                            Text(HomeLocalActivityFormatter.radiusText(meters)).tag(meters)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if carryingCandidates.isEmpty {
                        Text("譲る候補なし")
                            .foregroundStyle(MegrumTheme.muted)
                    } else {
                        ForEach(carryingCandidates) { candidate in
                            Toggle(isOn: carryingBinding(for: candidate.id)) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(candidate.title)
                                        .font(.body.weight(.semibold))
                                    Text(candidate.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(MegrumTheme.muted)
                                }
                            }
                        }
                    }
                } header: {
                    Text("持参するグッズ")
                }
            }
            .navigationTitle("現地交換")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("適用") {
                        onSave(draft.settings(savedAt: .now, original: settings))
                        dismiss()
                    }
                    .disabled(!draft.canSave || locationState.isResolvingLocationLabel)
                }
            }
            .onChange(of: locationState.coordinate) { _, coordinate in
                guard let coordinate else {
                    return
                }
                draft.coordinate = coordinate
                draft.venue = locationState.resolvedLocationLabel ?? "住所を確認中"
            }
            .onChange(of: locationState.resolvedLocationLabel) { _, label in
                guard let label, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return
                }
                draft.venue = label
            }
            .onChange(of: draft.isEnabled) { _, isEnabled in
                guard isEnabled else {
                    return
                }
                locationState.requestCurrentLocation()
            }
            .onAppear {
                guard let coordinate = draft.coordinate,
                      HomeLocalLocationLabel.isCoordinateBackedText(draft.venue)
                else {
                    return
                }
                locationState.resolveKnownCoordinate(coordinate)
            }
        }
    }

    private var locationButtonTitle: String {
        if locationState.isRequestingLocation {
            return "現在地を取得中"
        }
        if locationState.isResolvingLocationLabel {
            return "住所を確認中"
        }
        return draft.coordinate == nil ? "現在地を使う" : "現在地を更新"
    }

    private func carryingBinding(for id: UUID) -> Binding<Bool> {
        Binding {
            draft.selectedCarryingIDs.contains(id)
        } set: { isSelected in
            if isSelected {
                draft.selectedCarryingIDs.insert(id)
            } else {
                draft.selectedCarryingIDs.remove(id)
            }
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        switch minutes {
        case 60:
            "1時間"
        case 120:
            "2時間"
        case 180:
            "3時間"
        case 360:
            "6時間"
        default:
            "\(minutes)分"
        }
    }
}

struct HomeLocalActivityDraft: Equatable {
    var isEnabled: Bool
    var venue: String
    var coordinate: MegrumLocationCoordinate?
    var durationMinutes: Int
    var radiusMeters: Int
    var selectedCarryingIDs: Set<UUID>

    init(settings: HomeLocalActivitySettings, fallbackPrefecture: String?) {
        let inferredCoordinate = settings.coordinate ?? HomeLocalLocationLabel.coordinate(in: settings.venue)
        let displayVenue = settings.displayVenue(fallbackPrefecture: fallbackPrefecture)
        self.isEnabled = settings.isEnabled
        self.venue = displayVenue == "現在地未設定"
            ? ""
            : displayVenue
        self.coordinate = inferredCoordinate
        self.durationMinutes = settings.durationMinutes
        self.radiusMeters = settings.radiusMeters
        self.selectedCarryingIDs = settings.selectedCarryingIDs
    }

    var canSave: Bool {
        !isEnabled || !venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func settings(savedAt now: Date, original: HomeLocalActivitySettings) -> HomeLocalActivitySettings {
        let normalizedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldRestartWindow = isEnabled && (!original.isEnabled || original.status(now: now) == .expired)
        return HomeLocalActivitySettings(
            activityWindowID: original.activityWindowID,
            isEnabled: isEnabled,
            venue: normalizedVenue,
            coordinate: coordinate,
            startedAt: shouldRestartWindow ? now : original.startedAt,
            durationMinutes: durationMinutes,
            radiusMeters: radiusMeters,
            selectedCarryingIDs: selectedCarryingIDs
        )
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
