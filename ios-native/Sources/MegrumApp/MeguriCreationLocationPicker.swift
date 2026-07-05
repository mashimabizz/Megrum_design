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
            MeguriCreationLocationPickerHeader(
                title: title,
                subtitle: subtitle,
                isRequestingLocation: isRequestingLocation,
                onRequestLocation: requestAndCenterLocation
            )

            ZStack {
                if let baseCoordinate {
                    map(baseCoordinate: baseCoordinate)
                } else {
                    MeguriCreationMissingLocationView(
                        isRequestingLocation: isRequestingLocation,
                        onRequestLocation: onRequestLocation
                    )
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }

            MeguriCreationLocationCaption(selectionCaption: selectionCaption)
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
            .mapStyle(MeguriMapVisualStyle.quietStandard)
            .overlay {
                MeguriMapBrandToneOverlay(
                    topWhiteOpacity: 0.46,
                    middleWhiteOpacity: 0.14,
                    bottomWhiteOpacity: 0.02
                )
            }
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
