@testable import MegrumApp
import MapKit
import MegrumCore
import XCTest

@MainActor
final class MeguriMapDensityPlannerTests: XCTestCase {
    func testDensityModeActivatesOnlyWhenZoomedOut() {
        XCTAssertFalse(MeguriMapDensityPlanner.isDensityMode(spanLatitudeDelta: 0.03))
        XCTAssertFalse(
            MeguriMapDensityPlanner.isDensityMode(
                spanLatitudeDelta: MeguriMapDensityPlanner.activationSpanLatitudeDelta
            )
        )
        XCTAssertTrue(MeguriMapDensityPlanner.isDensityMode(spanLatitudeDelta: 0.3))
    }

    func testCellDegreesScalesWithSpanAndClamps() {
        XCTAssertEqual(
            MeguriMapDensityPlanner.cellDegrees(spanLatitudeDelta: 0.5),
            0.1,
            accuracy: 0.0001
        )
        // 下限クランプ（約2km）
        XCTAssertEqual(
            MeguriMapDensityPlanner.cellDegrees(spanLatitudeDelta: 0.01),
            MeguriMapDensityPlanner.minCellDegrees
        )
        // 上限クランプ
        XCTAssertEqual(
            MeguriMapDensityPlanner.cellDegrees(spanLatitudeDelta: 100),
            MeguriMapDensityPlanner.maxCellDegrees
        )
    }

    func testFetchBoundsPadsVisibleRegionAndClampsToWorld() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        let bounds = MeguriMapDensityPlanner.fetchBounds(region: region)
        XCTAssertEqual(bounds.minLatitude, 34.25, accuracy: 0.0001)
        XCTAssertEqual(bounds.maxLatitude, 35.75, accuracy: 0.0001)
        XCTAssertEqual(bounds.minLongitude, 138.25, accuracy: 0.0001)
        XCTAssertEqual(bounds.maxLongitude, 139.75, accuracy: 0.0001)

        let polar = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 89.9, longitude: 179.9),
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        )
        let clamped = MeguriMapDensityPlanner.fetchBounds(region: polar)
        XCTAssertEqual(clamped.maxLatitude, 90)
        XCTAssertEqual(clamped.maxLongitude, 180)
    }

    func testZoomSpanAlwaysEntersPinMode() {
        for span in [0.2, 1.0, 10.0, 40.0] {
            let target = MeguriMapDensityPlanner.zoomSpan(currentSpanLatitudeDelta: span)
            XCTAssertFalse(
                MeguriMapDensityPlanner.isDensityMode(spanLatitudeDelta: target),
                "span \(span) -> target \(target) はピン表示モードに入るべき"
            )
            XCTAssertGreaterThanOrEqual(target, 0.02)
        }
    }

    func testDensityCellTotalsAndIdentity() {
        let cell = MeguriMapDensityCell(latitude: 35.05, longitude: 139.15, groomCount: 12, threadCount: 3)
        XCTAssertEqual(cell.totalCount, 15)
        XCTAssertEqual(cell.id, "35.05:139.15")
    }
}
