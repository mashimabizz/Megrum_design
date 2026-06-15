import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

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

                HomeLocalCarryingSelectionSection(
                    carryingCandidates: carryingCandidates,
                    selectedCarryingIDs: $draft.selectedCarryingIDs
                )
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
                guard let label, !label.isBlank else {
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
        !isEnabled || !venue.isBlank
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
