import CoreLocation
import MegrumCore

enum MeguriAccessPolicy {
    static let groomOpenRadiusMeters: CLLocationDistance = 1_000
    static let boardOpenRadiusMeters: CLLocationDistance = 1_000
    static let creationRadiusMeters: CLLocationDistance = 1_000
    static let outOfRangeTitle = "圏外のため見ることができません"

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

    static func distanceMeters(
        from currentCoordinate: MegrumLocationCoordinate?,
        to thread: BoardThread
    ) -> CLLocationDistance? {
        guard let currentCoordinate,
              let latitude = thread.latitude,
              let longitude = thread.longitude
        else {
            return nil
        }
        let currentLocation = CLLocation(
            latitude: currentCoordinate.latitude,
            longitude: currentCoordinate.longitude
        )
        let threadLocation = CLLocation(
            latitude: latitude,
            longitude: longitude
        )
        return currentLocation.distance(from: threadLocation)
    }

    static func distanceMeters(
        from currentCoordinate: MegrumLocationCoordinate?,
        to selectedCoordinate: MegrumLocationCoordinate?
    ) -> CLLocationDistance? {
        guard let currentCoordinate, let selectedCoordinate else {
            return nil
        }
        let currentLocation = CLLocation(
            latitude: currentCoordinate.latitude,
            longitude: currentCoordinate.longitude
        )
        let selectedLocation = CLLocation(
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude
        )
        return currentLocation.distance(from: selectedLocation)
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

    static func canOpenBoard(
        _ thread: BoardThread,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> Bool {
        if thread.authorID == viewerID {
            return true
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: thread) else {
            return false
        }
        return distance <= boardOpenRadiusMeters
    }

    static func canCreateAt(
        _ selectedCoordinate: MegrumLocationCoordinate?,
        currentCoordinate: MegrumLocationCoordinate?
    ) -> Bool {
        guard let distance = distanceMeters(
            from: currentCoordinate,
            to: selectedCoordinate
        ) else {
            return false
        }
        return distance <= creationRadiusMeters
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
        return "現在地から\(distance.meguriDistanceText)。1km圏外のグルームは見ることができません"
    }

    static func boardAccessMessage(
        _ thread: BoardThread,
        currentCoordinate: MegrumLocationCoordinate?,
        viewerID: UUID?
    ) -> String {
        if thread.authorID == viewerID {
            return ""
        }
        guard let distance = distanceMeters(from: currentCoordinate, to: thread) else {
            return "現在地取得後に掲示板を開けます"
        }
        return "現在地から\(distance.meguriDistanceText)。1km圏外の掲示板は見ることができません"
    }

    static func creationLocationMessage(
        selectedCoordinate: MegrumLocationCoordinate?,
        currentCoordinate: MegrumLocationCoordinate?
    ) -> String {
        guard currentCoordinate != nil else {
            return "現在地を確認してから作成場所を選んでください"
        }
        guard let distance = distanceMeters(
            from: currentCoordinate,
            to: selectedCoordinate
        ) else {
            return "地図上で作成場所を選んでください"
        }
        return "現在地から\(distance.meguriDistanceText)。1km圏外には作成できません"
    }
}
