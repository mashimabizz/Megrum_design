import CoreLocation
import Foundation

struct MegrumLocationCoordinate: Equatable, Sendable {
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
final class MegrumLocationState: NSObject, ObservableObject {
    @Published private(set) var coordinate: MegrumLocationCoordinate?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isRequestingLocation = false
    @Published private(set) var locationErrorMessage: String?

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() {
        locationErrorMessage = nil
        authorizationStatus = manager.authorizationStatus

        guard CLLocationManager.locationServicesEnabled() else {
            isRequestingLocation = false
            locationErrorMessage = "位置情報サービスがオフです"
            return
        }

        switch authorizationStatus {
        case .notDetermined:
            isRequestingLocation = true
            #if os(iOS)
            manager.requestWhenInUseAuthorization()
            #else
            manager.requestAlwaysAuthorization()
            #endif
        case .authorizedAlways:
            isRequestingLocation = true
            manager.requestLocation()
        #if os(iOS)
        case .authorizedWhenInUse:
            isRequestingLocation = true
            manager.requestLocation()
        #endif
        case .denied, .restricted:
            isRequestingLocation = false
            locationErrorMessage = Self.message(for: authorizationStatus)
        @unknown default:
            isRequestingLocation = false
            locationErrorMessage = "位置情報を取得できません"
        }
    }
}

extension MegrumLocationState: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            if isAuthorized {
                requestCurrentLocation()
            } else if status != .notDetermined {
                isRequestingLocation = false
                locationErrorMessage = Self.message(for: status)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        let coordinate = MegrumLocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        Task { @MainActor in
            self.coordinate = coordinate
            isRequestingLocation = false
            locationErrorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isRequestingLocation = false
            if let error = error as? CLError, error.code == .denied {
                authorizationStatus = .denied
                locationErrorMessage = Self.message(for: .denied)
            } else {
                locationErrorMessage = "位置情報を取得できません"
            }
        }
    }
}

private extension MegrumLocationState {
    var isAuthorized: Bool {
        #if os(iOS)
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
        #else
        authorizationStatus == .authorizedAlways
        #endif
    }

    static func message(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .denied:
            "位置情報が許可されていません"
        case .restricted:
            "この端末では位置情報を利用できません"
        default:
            "位置情報を取得できません"
        }
    }
}
