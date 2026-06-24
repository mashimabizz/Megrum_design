import MapKit
import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceActionRow: View {
    var isRequestingLocation: Bool
    var canApplyPreviousDraft: Bool
    var onUseCurrentLocation: () -> Void
    var onApplyPreviousDraft: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                onUseCurrentLocation()
            } label: {
                Label {
                    Text("現在地を中心に")
                } icon: {
                    if isRequestingLocation {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "location.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .proposalPlaceSheetActionStyle(isEnabled: true)

            Button {
                onApplyPreviousDraft()
            } label: {
                Label("前の設定と同じに", systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .proposalPlaceSheetActionStyle(isEnabled: canApplyPreviousDraft)
            .disabled(!canApplyPreviousDraft)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
    }
}

struct ProposalMeetupPlaceMapCard: View {
    @Binding var cameraPosition: MapCameraPosition
    var selectedCoordinate: CLLocationCoordinate2D?
    var markerTitle: String
    var coordinateCaption: String
    var onSelectCoordinate: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("地図で場所を選択", systemImage: "map")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    if let selectedCoordinate {
                        Marker(markerTitle.isEmpty ? "待ち合わせ" : markerTitle, coordinate: selectedCoordinate)
                            .tint(MegrumTheme.lavender)
                    }
                }
                .frame(height: 216)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                }
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coordinate = proxy.convert(value.location, from: .local) else {
                                return
                            }
                            onSelectCoordinate(coordinate)
                        }
                )
            }

            Text(coordinateCaption)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct ProposalMeetupPlaceSearchResultsList: View {
    var results: [ProposalMeetupPlaceSearchResult]
    var onSelect: (ProposalMeetupPlaceSearchResult) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(results) { result in
                Button {
                    onSelect(result)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(result.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MegrumTheme.lavender.opacity(0.1), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }
}

struct ProposalMeetupPlaceStatusRow: View {
    var canSave: Bool
    var message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: canSave ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(canSave ? MegrumTheme.ok : MegrumTheme.pink)
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

struct ProposalMeetupPlaceSaveButton: View {
    var canSave: Bool
    var onSave: () -> Void

    var body: some View {
        Button {
            onSave()
        } label: {
            Text("この場所にする")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: ProposalFlowBottomBarMetrics.buttonMinHeight)
                .background(
                    MegrumTheme.lavender,
                    in: RoundedRectangle(cornerRadius: ProposalFlowBottomBarMetrics.buttonCornerRadius, style: .continuous)
                )
                .shadow(color: MegrumTheme.lavender.opacity(canSave ? 0.28 : 0), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.48)
        .padding(.horizontal, ProposalFlowBottomBarMetrics.horizontalPadding)
        .padding(.top, ProposalFlowBottomBarMetrics.topPadding)
        .padding(.bottom, ProposalFlowBottomBarMetrics.bottomPadding)
        .background(MegrumTheme.canvas.ignoresSafeArea(edges: .bottom))
    }
}

extension View {
    func proposalPlaceSheetActionStyle(isEnabled: Bool) -> some View {
        self
            .foregroundStyle(isEnabled ? MegrumTheme.ink : MegrumTheme.muted)
            .frame(height: 44)
            .padding(.horizontal, 10)
            .background(.white.opacity(isEnabled ? 0.82 : 0.46), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.lavender.opacity(isEnabled ? 0.22 : 0.08), lineWidth: 1)
            }
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.58)
    }

    @ViewBuilder
    func proposalPlaceSheetTextInputBehavior() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    func proposalFlowMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}
