import Foundation
import MegrumCore
import XCTest
@testable import MegrumApp

final class GroomNearbyStoryResolverTests: XCTestCase {
    func testConnectsGroomsWithinOneKilometerRegardlessOfAuthor() {
        let anchor = makeGroom(id: 1, latitude: 35.0, longitude: 139.0)
        // 緯度0.005度 ≒ 555m（圏内）、0.02度 ≒ 2.2km（圏外）
        let nearOther = makeGroom(id: 2, latitude: 35.005, longitude: 139.0)
        let farAway = makeGroom(id: 3, latitude: 35.02, longitude: 139.0)

        let connected = GroomNearbyStoryResolver.connectedGrooms(
            around: anchor,
            in: [farAway, nearOther, anchor]
        )

        XCTAssertEqual(connected.map(\.id), [anchor.id, nearOther.id])
    }

    func testAnchorComesFirstAndOthersSortedByDistance() {
        let anchor = makeGroom(id: 1, latitude: 35.0, longitude: 139.0)
        let closest = makeGroom(id: 2, latitude: 35.001, longitude: 139.0)
        let farther = makeGroom(id: 3, latitude: 35.006, longitude: 139.0)

        let connected = GroomNearbyStoryResolver.connectedGrooms(
            around: anchor,
            in: [farther, closest]
        )

        XCTAssertEqual(connected.map(\.id), [anchor.id, closest.id, farther.id])
    }

    func testAnchorAloneWhenNoNearbyGrooms() {
        let anchor = makeGroom(id: 1, latitude: 35.0, longitude: 139.0)
        let farAway = makeGroom(id: 2, latitude: 36.0, longitude: 139.0)

        let connected = GroomNearbyStoryResolver.connectedGrooms(around: anchor, in: [farAway])

        XCTAssertEqual(connected.map(\.id), [anchor.id])
    }

    private func makeGroom(id: Int, latitude: Double, longitude: Double) -> GroomPost {
        GroomPost(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            authorID: UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", id))!,
            imageURL: URL(string: "https://example.com/groom-\(id).png")!,
            latitude: latitude,
            longitude: longitude
        )
    }
}
