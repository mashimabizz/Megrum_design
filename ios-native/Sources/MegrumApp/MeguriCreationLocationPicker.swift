import Foundation
import MapKit
import MegrumDesign
import SwiftUI

struct MeguriCreationLocationPicker: View {
    var title: String
    var subtitle: String
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var preview: MeguriCreationLocationPreview = .pin
    @Binding var selectedCoordinate: MegrumLocationCoordinate?
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void

    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var hasPreparedInitialPosition = false

    private var baseCoordinate: MegrumLocationCoordinate? {
        currentCoordinate
    }

    private var selectionCaption: String {
        guard let selectedCoordinate else {
            return "地図上をタップして作成場所を選択"
        }
        guard let distance = MeguriAccessPolicy.distanceMeters(
            from: baseCoordinate,
            to: selectedCoordinate
        ) else {
            return "選択地点を確認中"
        }
        return "現在地から\(distance.meguriDistanceText)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: requestAndCenterLocation) {
                    Group {
                        if isRequestingLocation {
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .black))
                        }
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("現在地に戻る")
            }

            ZStack {
                if let baseCoordinate {
                    map(baseCoordinate: baseCoordinate)
                } else {
                    missingLocationPlaceholder
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)

                Text(selectionCaption)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.72))

                Spacer(minLength: 0)
            }
        }
        .onAppear(perform: prepareInitialSelectionIfNeeded)
        .onChange(of: currentCoordinate) { _, _ in
            prepareInitialSelectionIfNeeded()
        }
    }

    @ViewBuilder
    private func map(baseCoordinate: MegrumLocationCoordinate) -> some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                MapCircle(
                    center: baseCoordinate.clLocationCoordinate,
                    radius: MeguriAccessPolicy.creationRadiusMeters
                )
                .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)

                Annotation("現在地", coordinate: baseCoordinate.clLocationCoordinate) {
                    CurrentLocationDot()
                }

                if let selectedCoordinate {
                    Annotation("作成場所", coordinate: selectedCoordinate.clLocationCoordinate) {
                        SelectedCreationLocationAnnotation(preview: preview)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard let coordinate = proxy.convert(value.location, from: .local) else {
                            return
                        }
                        selectTappedCoordinate(coordinate, baseCoordinate: baseCoordinate)
                    }
            )
        }
    }

    private var missingLocationPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text("現在地を確認すると作成場所を選べます")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Button(action: onRequestLocation) {
                Text(isRequestingLocation ? "確認中" : "現在地を確認")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 38)
                    .background(MegrumTheme.lavender, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isRequestingLocation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.lavender.opacity(0.08))
    }

    private func prepareInitialSelectionIfNeeded() {
        guard let baseCoordinate else {
            return
        }
        if selectedCoordinate == nil {
            selectedCoordinate = baseCoordinate
        }
        if !hasPreparedInitialPosition {
            hasPreparedInitialPosition = true
            centerMap(on: selectedCoordinate ?? baseCoordinate, spanMeters: 1_550)
        }
    }

    private func requestAndCenterLocation() {
        onRequestLocation()
        if let baseCoordinate {
            selectedCoordinate = baseCoordinate
            centerMap(on: baseCoordinate, spanMeters: 1_550)
        }
    }

    private func selectTappedCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        baseCoordinate: MegrumLocationCoordinate
    ) {
        let tapped = MegrumLocationCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard MeguriAccessPolicy.canCreateAt(
            tapped,
            currentCoordinate: baseCoordinate
        ) else {
            onOutOfRange(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: tapped,
                    currentCoordinate: baseCoordinate
                )
            )
            return
        }
        selectedCoordinate = tapped
    }

    private func centerMap(on coordinate: MegrumLocationCoordinate, spanMeters: CLLocationDistance) {
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            latitudinalMeters: spanMeters,
            longitudinalMeters: spanMeters
        )
        withAnimation(.smooth(duration: 0.25)) {
            cameraPosition = .region(region)
        }
    }
}
