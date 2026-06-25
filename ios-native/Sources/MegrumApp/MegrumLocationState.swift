import CoreLocation
import Foundation

@MainActor
final class MegrumLocationState: NSObject, ObservableObject {
    @Published private(set) var coordinate: MegrumLocationCoordinate?
    @Published private(set) var resolvedLocationLabel: String?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isRequestingLocation = false
    @Published private(set) var isResolvingLocationLabel = false
    @Published private(set) var locationErrorMessage: String?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var resolvingCoordinate: MegrumLocationCoordinate?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation(clearsPreviousCoordinate: Bool = false) {
        locationErrorMessage = nil
        resolvedLocationLabel = nil
        if clearsPreviousCoordinate {
            coordinate = nil
        }
        authorizationStatus = manager.authorizationStatus

        guard CLLocationManager.locationServicesEnabled() else {
            isRequestingLocation = false
            isResolvingLocationLabel = false
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
            isResolvingLocationLabel = false
            locationErrorMessage = Self.message(for: authorizationStatus)
        @unknown default:
            isRequestingLocation = false
            isResolvingLocationLabel = false
            locationErrorMessage = "位置情報を取得できません"
        }
    }

    func resolveKnownCoordinate(_ coordinate: MegrumLocationCoordinate) {
        guard HomeLocalCoordinateStorageCodec.isValid(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ) else {
            resolvedLocationLabel = nil
            isResolvingLocationLabel = false
            return
        }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        resolveLocationLabel(for: location, coordinate: coordinate)
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
                isResolvingLocationLabel = false
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
            resolveLocationLabel(for: location, coordinate: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isRequestingLocation = false
            isResolvingLocationLabel = false
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
    func resolveLocationLabel(for location: CLLocation, coordinate: MegrumLocationCoordinate) {
        resolvingCoordinate = coordinate
        resolvedLocationLabel = nil
        isResolvingLocationLabel = true
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ja_JP")) { [weak self] placemarks, _ in
            Task { @MainActor in
                guard let self, self.resolvingCoordinate == coordinate else {
                    return
                }
                self.isResolvingLocationLabel = false
                self.resolvedLocationLabel = Self.displayLabel(for: placemarks?.first, fallback: coordinate)
            }
        }
    }

    static func displayLabel(for placemark: CLPlacemark?, fallback coordinate: MegrumLocationCoordinate) -> String {
        guard let placemark else {
            return HomeLocalLocationLabel.coordinateText(coordinate)
        }

        if let pointOfInterest = placemark.areasOfInterest?.first?.nilIfBlank {
            return pointOfInterest
        }

        if let name = placemark.name?.nilIfBlank,
           !name.contains(","),
           !name.isCoordinateLike {
            return name
        }

        let address = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare
        ]
        .compactMap { $0?.nilIfBlank }
        .joined()

        if !address.isEmpty {
            return address
        }

        return HomeLocalLocationLabel.coordinateText(coordinate)
    }

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

private extension String {
    var isCoordinateLike: Bool {
        let parts = split(separator: ",")
        guard parts.count == 2 else {
            return false
        }
        return parts.allSatisfy { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) != nil }
    }
}
