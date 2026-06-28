import CoreLocation
import Foundation

extension MegrumLocationState {
    var permissionPhase: MegrumLocationPermissionPhase {
        Self.permissionPhase(
            authorizationStatus: authorizationStatus,
            isRequestingLocation: isRequestingLocation,
            hasCoordinate: coordinate != nil,
            locationServicesEnabled: CLLocationManager.locationServicesEnabled(),
            hasError: locationErrorMessage != nil
        )
    }

    var meguriNotice: MegrumLocationNotice? {
        Self.meguriNotice(
            phase: permissionPhase,
            errorMessage: locationErrorMessage
        )
    }

    static func permissionPhase(
        authorizationStatus: CLAuthorizationStatus,
        isRequestingLocation: Bool,
        hasCoordinate: Bool,
        locationServicesEnabled: Bool,
        hasError: Bool
    ) -> MegrumLocationPermissionPhase {
        guard locationServicesEnabled else {
            return .servicesDisabled
        }
        if isRequestingLocation && !hasCoordinate {
            return .requesting
        }
        if hasError {
            switch authorizationStatus {
            case .denied:
                return .denied
            case .restricted:
                return .restricted
            default:
                return .failed
            }
        }
        switch authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedAlways:
            return .authorized
        #if os(iOS)
        case .authorizedWhenInUse:
            return .authorized
        #endif
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .failed
        }
    }

    static func meguriNotice(
        phase: MegrumLocationPermissionPhase,
        errorMessage: String?
    ) -> MegrumLocationNotice? {
        switch phase {
        case .servicesDisabled:
            return MegrumLocationNotice(message: "位置情報サービスがオフです", actionTitle: "設定")
        case .notDetermined:
            return MegrumLocationNotice(message: "現在地を許可すると、近くのグルームと1km圏内のチャットルームを表示できます", actionTitle: "許可")
        case .requesting:
            return MegrumLocationNotice(message: "現在地を確認しています", actionTitle: nil)
        case .authorized:
            return nil
        case .denied:
            return MegrumLocationNotice(message: errorMessage ?? "位置情報が許可されていません", actionTitle: "設定")
        case .restricted:
            return MegrumLocationNotice(message: errorMessage ?? "この端末では位置情報を利用できません", actionTitle: nil)
        case .failed:
            return MegrumLocationNotice(message: errorMessage ?? "位置情報を取得できません", actionTitle: "再試行")
        }
    }
}
