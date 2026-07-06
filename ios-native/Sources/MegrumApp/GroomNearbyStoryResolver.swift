import CoreLocation
import Foundation
import MegrumCore

/// 地図でグルームを開いた時に、半径1km圏内かつ地図上に表示されている
/// グルームを1つのストーリーとして繋げる（投稿者が誰かは問わない）。
enum GroomNearbyStoryResolver {
    static let radiusMeters: Double = 1000

    /// タップしたグルームを先頭に、1km圏内のグルームを近い順（同距離なら新しい順）で返す。
    static func connectedGrooms(
        around anchor: GroomPost,
        in grooms: [GroomPost],
        radiusMeters: Double = radiusMeters
    ) -> [GroomPost] {
        let anchorLocation = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)

        func distance(_ groom: GroomPost) -> Double {
            CLLocation(latitude: groom.latitude, longitude: groom.longitude)
                .distance(from: anchorLocation)
        }

        let nearby = grooms
            .filter { $0.id != anchor.id && distance($0) <= radiusMeters }
            .sorted { lhs, rhs in
                let lhsDistance = distance(lhs)
                let rhsDistance = distance(rhs)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return lhs.createdAt > rhs.createdAt
            }
        return [anchor] + nearby
    }
}
