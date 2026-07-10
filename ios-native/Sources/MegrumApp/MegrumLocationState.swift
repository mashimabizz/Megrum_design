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
    private var wantsContinuousLocationUpdates = false
    private var lastResolvedLocation: CLLocation?
    private static let continuousReverseGeocodeDistanceMeters: CLLocationDistance = 50

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    func requestCurrentLocation(clearsPreviousCoordinate: Bool = false) {
        requestLocation(clearsPreviousCoordinate: clearsPreviousCoordinate, continuous: false)
    }

    func startUpdatingCurrentLocation(clearsPreviousCoordinate: Bool = false) {
        wantsContinuousLocationUpdates = true
        requestLocation(clearsPreviousCoordinate: clearsPreviousCoordinate, continuous: true)
    }

    func stopUpdatingCurrentLocation() {
        wantsContinuousLocationUpdates = false
        manager.stopUpdatingLocation()
        isRequestingLocation = false
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
        lastResolvedLocation = location
        resolveLocationLabel(for: location, coordinate: coordinate)
    }
}

private extension MegrumLocationState {
    func requestLocation(clearsPreviousCoordinate: Bool, continuous: Bool) {
        locationErrorMessage = nil
        if clearsPreviousCoordinate {
            coordinate = nil
            resolvedLocationLabel = nil
            lastResolvedLocation = nil
        } else if !continuous {
            resolvedLocationLabel = nil
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
            // VisualQAプレビューでは許可ダイアログがスクショ検証を阻害するため要求しない（iter1226.406）。
            guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
                isRequestingLocation = false
                return
            }
            isRequestingLocation = true
            #if os(iOS)
            manager.requestWhenInUseAuthorization()
            #else
            manager.requestAlwaysAuthorization()
            #endif
        case .authorizedAlways:
            isRequestingLocation = true
            requestAuthorizedLocation(continuous: continuous)
        #if os(iOS)
        case .authorizedWhenInUse:
            isRequestingLocation = true
            requestAuthorizedLocation(continuous: continuous)
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

    func requestAuthorizedLocation(continuous: Bool) {
        if continuous {
            manager.startUpdatingLocation()
        } else {
            manager.requestLocation()
        }
    }
}

extension MegrumLocationState: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            if isAuthorized {
                // 許可された時点で古い「許可されていません」表示を確実に消す。
                locationErrorMessage = nil
                if wantsContinuousLocationUpdates {
                    startUpdatingCurrentLocation()
                } else {
                    requestCurrentLocation()
                }
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
            if shouldResolveLocationLabel(for: location) {
                resolveLocationLabel(for: location, coordinate: coordinate)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let currentStatus = manager.authorizationStatus
        Task { @MainActor in
            // 実際の許可状態を必ず読み直す。エラー種別から .denied を推測して
            // 上書きすると、許可済みなのに「許可されていません」が残り続ける。
            authorizationStatus = currentStatus
            if let error = error as? CLError {
                switch error.code {
                case .locationUnknown:
                    // 一時的に測位できないだけ。継続更新中は次の更新を待つ。
                    if wantsContinuousLocationUpdates {
                        return
                    }
                case .denied:
                    // 許可ダイアログ表示中のリクエスト等で、許可済みでも一時的に
                    // denied エラーが届くことがある。実状態が許可済みなら無視して継続。
                    if isAuthorized {
                        if wantsContinuousLocationUpdates {
                            self.manager.startUpdatingLocation()
                        }
                        return
                    }
                    isRequestingLocation = false
                    isResolvingLocationLabel = false
                    locationErrorMessage = Self.message(for: currentStatus == .notDetermined ? .denied : currentStatus)
                    return
                default:
                    break
                }
            }
            isRequestingLocation = false
            isResolvingLocationLabel = false
            locationErrorMessage = "位置情報を取得できません"
        }
    }
}

private extension MegrumLocationState {
    func shouldResolveLocationLabel(for location: CLLocation) -> Bool {
        guard wantsContinuousLocationUpdates else {
            lastResolvedLocation = location
            return true
        }

        guard let lastResolvedLocation else {
            self.lastResolvedLocation = location
            return true
        }

        guard location.distance(from: lastResolvedLocation) >= Self.continuousReverseGeocodeDistanceMeters else {
            return false
        }

        self.lastResolvedLocation = location
        return true
    }

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
