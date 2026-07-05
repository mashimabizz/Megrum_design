import CoreLocation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveMap: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var currentCoordinate: MegrumLocationCoordinate?
    var onSelect: (GroomPost) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if let currentCoordinate {
                Annotation("現在地", coordinate: currentCoordinate.clLocationCoordinate) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(MegrumTheme.lavender, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 10, y: 5)
                }
            }

            ForEach(grooms) { groom in
                Annotation("", coordinate: groom.coordinate) {
                    Button {
                        onSelect(groom)
                    } label: {
                        GroomArchiveMapPin(groom: groom)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(MeguriMapVisualStyle.quietStandard)
        .overlay {
            MeguriMapBrandToneOverlay(
                topWhiteOpacity: 0.72,
                middleWhiteOpacity: 0.16,
                bottomWhiteOpacity: 0.04
            )
        }
    }
}

private struct GroomArchiveMapPin: View {
    var groom: GroomPost

    var body: some View {
        MeguriPinPopIn {
            MeguriFloatingMotion(seed: groom.id.hashValue) {
                VStack(spacing: 4) {
                    GroomMapPin(groom: groom, isOutOfRange: false)

                    Text(groom.createdAt.formatted(.dateTime.month().day()))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.92), in: Capsule())
                        .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 6, y: 3)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("過去のグルーム")
    }
}

enum GroomArchiveMapRegion {
    static func region(
        for grooms: [GroomPost],
        currentCoordinate: MegrumLocationCoordinate?
    ) -> MKCoordinateRegion {
        var rect = MKMapRect.null

        if let currentCoordinate {
            rect = rect.union(rectAround(currentCoordinate.clLocationCoordinate, radiusMeters: 300))
        }

        for groom in grooms {
            rect = rect.union(rectAround(groom.coordinate, radiusMeters: 180))
        }

        guard !rect.isNull else {
            return MKCoordinateRegion(
                center: currentCoordinate?.clLocationCoordinate
                    ?? CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            )
        }

        let padded = rect.insetBy(dx: -rect.size.width * 0.24, dy: -rect.size.height * 0.24)
        let region = MKCoordinateRegion(padded)
        return MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(max(region.span.latitudeDelta, 0.018), 0.22),
                longitudeDelta: min(max(region.span.longitudeDelta * 1.28, 0.018), 0.22)
            )
        )
    }

    static func focusedRegion(for groom: GroomPost) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: groom.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.0065, longitudeDelta: 0.0065)
        )
    }

    private static func rectAround(
        _ coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance
    ) -> MKMapRect {
        let point = MKMapPoint(coordinate)
        let metersPerMapPoint = max(MKMetersPerMapPointAtLatitude(coordinate.latitude), 0.000_001)
        let radiusMapPoints = max(radiusMeters / metersPerMapPoint, 1)
        return MKMapRect(
            x: point.x - radiusMapPoints,
            y: point.y - radiusMapPoints,
            width: radiusMapPoints * 2,
            height: radiusMapPoints * 2
        )
    }
}
