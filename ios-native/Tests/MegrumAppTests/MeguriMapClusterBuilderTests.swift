import Foundation
import MegrumCore
import XCTest
@testable import MegrumApp

final class MeguriMapClusterBuilderTests: XCTestCase {
    func testFarApartMarkersStaySingle() {
        let elements = MeguriMapClusterBuilder.elements(
            grooms: [
                makeGroom(idSuffix: "001", latitude: 35.00, longitude: 139.00),
                makeGroom(idSuffix: "002", latitude: 35.30, longitude: 139.30)
            ],
            threads: [],
            spanLatitudeDelta: 0.05
        )
        XCTAssertEqual(elements.count, 2)
        XCTAssertTrue(elements.allSatisfy { element in
            if case .single = element { return true }
            return false
        })
    }

    func testNearbyMarkersMergeIntoClusterAtMidpoint() {
        let elements = MeguriMapClusterBuilder.elements(
            grooms: [
                makeGroom(idSuffix: "001", latitude: 35.0001, longitude: 139.0001),
                makeGroom(idSuffix: "002", latitude: 35.0003, longitude: 139.0003)
            ],
            threads: [makeThread(idSuffix: "003", latitude: 35.0002, longitude: 139.0002)],
            spanLatitudeDelta: 0.5
        )
        XCTAssertEqual(elements.count, 1)
        guard case .cluster(let cluster) = elements[0] else {
            XCTFail("expected cluster")
            return
        }
        XCTAssertEqual(cluster.count, 3)
        XCTAssertEqual(cluster.latitude, 35.0002, accuracy: 0.00005)
        XCTAssertEqual(cluster.longitude, 139.0002, accuracy: 0.00005)
    }

    func testZoomingInSplitsCluster() {
        let grooms = [
            makeGroom(idSuffix: "001", latitude: 35.000, longitude: 139.000),
            makeGroom(idSuffix: "002", latitude: 35.010, longitude: 139.010),
            makeGroom(idSuffix: "003", latitude: 35.020, longitude: 139.020)
        ]
        let zoomedOut = MeguriMapClusterBuilder.elements(
            grooms: grooms,
            threads: [],
            spanLatitudeDelta: 1.0
        )
        XCTAssertEqual(zoomedOut.count, 1)
        guard case .cluster(let cluster) = zoomedOut[0] else {
            XCTFail("expected cluster")
            return
        }

        let splitSpan = MeguriMapClusterBuilder.splitSpan(
            for: cluster,
            currentSpanLatitudeDelta: 1.0
        )
        XCTAssertLessThan(splitSpan, 1.0)
        // 分解後のマーカーの広がりが視界に収まるスパンであること。
        XCTAssertGreaterThanOrEqual(splitSpan, 0.02)

        let zoomedIn = MeguriMapClusterBuilder.elements(
            items: cluster.items,
            spanLatitudeDelta: splitSpan
        )
        XCTAssertGreaterThanOrEqual(zoomedIn.count, 2)
    }

    func testMarkersWithoutCoordinatesAreDropped() {
        let elements = MeguriMapClusterBuilder.elements(
            grooms: [],
            threads: [makeThread(idSuffix: "001", latitude: nil, longitude: nil)],
            spanLatitudeDelta: 0.05
        )
        XCTAssertTrue(elements.isEmpty)
    }

    private func makeGroom(idSuffix: String, latitude: Double, longitude: Double) -> GroomPost {
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            authorID: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            imageURL: URL(string: "https://example.com/groom-\(idSuffix).jpg")!,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func makeThread(idSuffix: String, latitude: Double?, longitude: Double?) -> BoardThread {
        BoardThread(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000\(idSuffix)")!,
            authorID: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            title: "テストスレッド\(idSuffix)",
            body: "本文",
            audience: .nearby3km,
            latitude: latitude,
            longitude: longitude
        )
    }
}
