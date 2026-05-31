import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeLocalActivitySettings: Equatable {
    var isEnabled: Bool
    var venue: String
    var startedAt: Date?
    var durationMinutes: Int
    var radiusMeters: Int
    var selectedCarryingIDs: Set<UUID>

    static let defaultDurationMinutes = 120
    static let defaultRadiusMeters = 500
    static let durationOptions = [60, 120, 180, 360]
    static let radiusOptions = [300, 500, 1_000, 2_000]

    var normalizedVenue: String {
        venue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func displayVenue(fallbackPrefecture: String?) -> String {
        if !normalizedVenue.isEmpty {
            return normalizedVenue
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
    static func coordinateText(latitude: Double, longitude: Double) -> String {
        String(format: "現在地 %.4f, %.4f", locale: Locale(identifier: "en_US_POSIX"), latitude, longitude)
    }

    static func coordinateText(_ coordinate: MegrumLocationCoordinate) -> String {
        coordinateText(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct HomeLocalModeSurface: View {
    var viewer: UserProfile?
    var settings: HomeLocalActivitySettings
    var carryingCandidates: [HomeLocalCarryingCandidate]
    var onEdit: () -> Void

    var body: some View {
        let now = Date()
        let status = settings.status(now: now)
        let carryingSummary = settings.carryingSummary(from: carryingCandidates)

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
        .accessibilityValue("\(status.label)、\(settings.displayVenue(fallbackPrefecture: viewer?.prefecture))、\(settings.timeWindowText(now: Date()))、\(settings.radiusText)、\(carryingSummary.countText)")
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
        NavigationStack {
            Form {
                Section {
                    Toggle("現地交換モード", isOn: $draft.isEnabled)
                }

                Section("場所") {
                    TextField("会場・駅・エリア", text: $draft.venue)

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
                    .disabled(!draft.canSave)
                }
            }
            .onChange(of: locationState.coordinate) { _, coordinate in
                guard let coordinate else {
                    return
                }
                draft.venue = HomeLocalLocationLabel.coordinateText(coordinate)
            }
        }
    }

    private var locationButtonTitle: String {
        locationState.isRequestingLocation ? "現在地を取得中" : "現在地を使う"
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
    var durationMinutes: Int
    var radiusMeters: Int
    var selectedCarryingIDs: Set<UUID>

    init(settings: HomeLocalActivitySettings, fallbackPrefecture: String?) {
        self.isEnabled = settings.isEnabled
        self.venue = settings.displayVenue(fallbackPrefecture: fallbackPrefecture) == "現在地未設定"
            ? ""
            : settings.displayVenue(fallbackPrefecture: fallbackPrefecture)
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
            isEnabled: isEnabled,
            venue: normalizedVenue,
            startedAt: shouldRestartWindow ? now : original.startedAt,
            durationMinutes: durationMinutes,
            radiusMeters: radiusMeters,
            selectedCarryingIDs: selectedCarryingIDs
        )
    }
}
