import CoreLocation
import MapKit

enum MeguriMapKind: String, Identifiable {
    case all
    case grooms
    case boards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "めぐりマップ"
        case .grooms:
            "グルームマップ"
        case .boards:
            "チャットルームマップ"
        }
    }

    var homeDisplayLabel: String {
        switch self {
        case .all:
            "すべて"
        case .grooms:
            "グルーム"
        case .boards:
            "掲示板"
        }
    }

    var homeSystemImage: String {
        switch self {
        case .all:
            "square.grid.2x2.fill"
        case .grooms:
            "camera.fill"
        case .boards:
            "bubble.left.and.bubble.right.fill"
        }
    }

    var nextHomeKind: MeguriMapKind {
        switch self {
        case .all:
            .grooms
        case .grooms:
            .boards
        case .boards:
            .all
        }
    }

    var radiusMeters: CLLocationDistance {
        switch self {
        case .all:
            MeguriAccessPolicy.boardOpenRadiusMeters
        case .grooms:
            MeguriAccessPolicy.groomOpenRadiusMeters
        case .boards:
            MeguriAccessPolicy.boardOpenRadiusMeters
        }
    }

    var regionSpan: MKCoordinateSpan {
        switch self {
        case .all:
            MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        }
    }
}
