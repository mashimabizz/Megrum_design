import Foundation
import MegrumDesign
import SwiftUI

struct HomeLocalModeSettingsContent: View {
    @Binding var draft: HomeLocalActivityDraft
    var settings: HomeLocalActivitySettings
    var publicPreview: HomeLocalPublicPreview
    var carryingCandidates: [HomeLocalCarryingCandidate]
    var locationButtonTitle: String
    var isRequestingLocation: Bool
    var isResolvingLocationLabel: Bool
    var locationErrorMessage: String?
    var resolvedLocationLabel: String?
    var onRequestCurrentLocation: () -> Void
    var durationLabel: (Int) -> String

    var body: some View {
        Form {
            enabledSection
            publicPreviewSection
            locationSection
            durationSection
            radiusSection
            HomeLocalCarryingSelectionSection(
                carryingCandidates: carryingCandidates,
                selectedCarryingIDs: $draft.selectedCarryingIDs
            )
        }
    }

    private var enabledSection: some View {
        Section {
            Toggle("現地交換モード", isOn: $draft.isEnabled)
        }
    }

    private var publicPreviewSection: some View {
        Section {
            LabeledContent("反映先", value: settings.activityWindowID == nil ? "現在地を新しく反映" : "現在地を上書き")
            HomeLocalPublicPreviewListRow(preview: publicPreview)
        } header: {
            Text("現在地の表示")
        } footer: {
            Text("ONの間は、現在地・有効時間・半径・持参グッズが現地マッチに使われます。")
        }
    }

    private var locationSection: some View {
        Section("現在地") {
            TextField("建物名・会場・駅・エリア", text: $draft.venue)

            Button {
                onRequestCurrentLocation()
            } label: {
                Label(locationButtonTitle, systemImage: "location")
            }
            .disabled(isRequestingLocation)

            if let locationErrorMessage {
                Text(locationErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let coordinate = draft.coordinate {
                LabeledContent("取得した場所", value: locationLabel(for: coordinate))
            }
        }
    }

    private var durationSection: some View {
        Section("有効時間") {
            Picker("有効時間", selection: $draft.durationMinutes) {
                ForEach(HomeLocalActivitySettings.durationOptions, id: \.self) { minutes in
                    Text(durationLabel(minutes)).tag(minutes)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var radiusSection: some View {
        Section("半径") {
            Picker("半径", selection: $draft.radiusMeters) {
                ForEach(HomeLocalActivitySettings.radiusOptions, id: \.self) { meters in
                    Text(HomeLocalActivityFormatter.radiusText(meters)).tag(meters)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func locationLabel(for coordinate: MegrumLocationCoordinate) -> String {
        resolvedLocationLabel
            ?? (isResolvingLocationLabel
                ? HomeLocalLocationLabel.resolvingText
                : HomeLocalLocationLabel.coordinateText(coordinate))
    }
}
