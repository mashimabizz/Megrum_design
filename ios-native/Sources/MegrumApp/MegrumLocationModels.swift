import CoreLocation
import Foundation

struct MegrumLocationCoordinate: Equatable, Sendable {
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MegrumLocationPermissionPhase: Equatable, Sendable {
    case servicesDisabled
    case notDetermined
    case requesting
    case authorized
    case denied
    case restricted
    case failed
}

struct MegrumLocationNotice: Equatable, Sendable {
    var message: String
    var actionTitle: String?
}
