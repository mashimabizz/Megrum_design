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
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.72), .white.opacity(0.16), .white.opacity(0.04)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
    }
}

private struct GroomArchiveMapPin: View {
    var groom: GroomPost

    var body: some View {
        VStack(spacing: 0) {
            GroomThumbnailCircle(url: groom.imageURL, size: 62)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(MegrumTheme.ink, in: Circle())
                        .offset(x: 4, y: 4)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)

            GroomArchiveTriangle()
                .fill(MegrumTheme.lavender)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
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

private struct GroomArchiveTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
