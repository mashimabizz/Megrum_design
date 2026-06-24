import CoreLocation
import MapKit

enum MeguriMapKind: String, Identifiable {
    case grooms
    case boards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grooms:
            "グルームマップ"
        case .boards:
            "掲示板マップ"
        }
    }

    var radiusMeters: CLLocationDistance {
        switch self {
        case .grooms:
            MeguriAccessPolicy.groomOpenRadiusMeters
        case .boards:
            MeguriAccessPolicy.boardOpenRadiusMeters
        }
    }

    var regionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        }
    }
}
