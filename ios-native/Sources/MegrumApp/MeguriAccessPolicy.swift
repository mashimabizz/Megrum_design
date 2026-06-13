import CoreLocation
import MegrumCore

enum MeguriAccessPolicy {
    static let groomOpenRadiusMeters: CLLocationDistance = 1_000
    static let boardNearbyRadiusMeters: CLLocationDistance = 3_000

    static func distanceMeters(
        from currentCoordinate: MegrumLocationCoordinate?,
        to groom: GroomPost
    ) -> CLLocationDistance? {
        guard let currentCoordinate else {
            return nil
        }
        let currentLocation = CLLocation(
            latitude: currentCoordinate.latitude,
            longitude: currentCoordinate.longitude
        )
        let groomLocation = CLLocation(
            latitude: groom.latitude,
            longitude: groom.longitude
        )
        return currentLocation.distance(from: groomLocation)
    }

    static func canOpenGroom(
        _ groom: GroomPost,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> Bool {
        if groom.authorID == viewerID {
            return true
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: groom) else {
            return false
        }
        return distance <= groomOpenRadiusMeters
    }

    static func groomAccessMessage(
        _ groom: GroomPost,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> String {
        if groom.authorID == viewerID {
            return ""
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: groom) else {
            return "現在地取得後にグルームを開けます"
        }
        return "現在地から\(distance.meguriDistanceText)。1km圏外のグルームは見れません"
    }
}
