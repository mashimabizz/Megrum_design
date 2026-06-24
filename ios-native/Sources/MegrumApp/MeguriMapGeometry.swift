import CoreLocation
import MapKit
import MegrumCore

extension GroomPost {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension MeguriMapKind {
    func initialCenter(userCoordinate: MegrumLocationCoordinate?, grooms: [GroomPost], threads: [BoardThread]) -> CLLocationCoordinate2D {
        if let userCoordinate {
            return userCoordinate.clLocationCoordinate
        }

        switch self {
        case .grooms:
            return grooms.first?.coordinate ?? Self.fallbackCenter
        case .boards:
            if let thread = threads.first(where: { $0.latitude != nil && $0.longitude != nil }),
               let latitude = thread.latitude,
               let longitude = thread.longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return Self.fallbackCenter
        }
    }

    func visibleRegion(
        userCoordinate: MegrumLocationCoordinate?,
        grooms: [GroomPost],
        threads: [BoardThread],
        boardScope: BoardThread.Audience
    ) -> MKCoordinateRegion {
        let userLocation = userCoordinate?.clLocationCoordinate
        var rect = MKMapRect.null

        if let userLocation, shouldCenterRangeCircle {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: radiusMeters))
        } else if let userLocation, annotationCoordinates(grooms: grooms, threads: threads).isEmpty {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: 220))
        }

        for coordinate in annotationCoordinates(grooms: grooms, threads: threads) where coordinate.isMeguriValid {
            rect = rect.union(.meguriRect(centeredAt: coordinate, radiusMeters: 150))
        }

        guard !rect.isNull else {
            return MKCoordinateRegion(
                center: initialCenter(userCoordinate: userCoordinate, grooms: grooms, threads: threads),
                span: regionSpan
            )
        }

        return MKCoordinateRegion(rect.meguriPadded())
            .meguriClamped(minimum: minimumRegionSpan, maximum: maximumRegionSpan)
    }

    private func annotationCoordinates(grooms: [GroomPost], threads: [BoardThread]) -> [CLLocationCoordinate2D] {
        switch self {
        case .grooms:
            return grooms.map(\.coordinate)
        case .boards:
            return threads.compactMap { thread in
                guard let latitude = thread.latitude, let longitude = thread.longitude else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }

    private var shouldCenterRangeCircle: Bool {
        switch self {
        case .grooms, .boards:
            return true
        }
    }

    private var minimumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        }
    }

    private var maximumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        }
    }

    private static var fallbackCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    }
}

private extension MKMapRect {
    static func meguriRect(centeredAt coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) -> MKMapRect {
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

    func meguriPadded(fraction: Double = 0.24) -> MKMapRect {
        insetBy(dx: -size.width * fraction, dy: -size.height * fraction)
    }
}

private extension MKCoordinateRegion {
    func meguriClamped(minimum: MKCoordinateSpan, maximum: MKCoordinateSpan) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta.meguriClamped(minimum.latitudeDelta, maximum.latitudeDelta),
                longitudeDelta: span.longitudeDelta.meguriClamped(minimum.longitudeDelta, maximum.longitudeDelta)
            )
        )
    }
}

private extension CLLocationCoordinate2D {
    var isMeguriValid: Bool {
        CLLocationCoordinate2DIsValid(self)
    }
}

private extension Double {
    func meguriClamped(_ lowerBound: Double, _ upperBound: Double) -> Double {
        min(max(self, lowerBound), upperBound)
    }
}

extension CLLocationDistance {
    var meguriDistanceText: String {
        if self < 1_000 {
            return "\(Int(rounded()))m"
        }
        return String(format: "%.1fkm", self / 1_000)
    }
}
