@testable import MegrumApp
import CoreGraphics
import XCTest

@MainActor
final class GroomViewerCubeGeometryTests: XCTestCase {
    private let width: CGFloat = 390

    func testForwardOutgoingFaceRotatesAwayAroundTrailingEdge() {
        let start = GroomViewerCubeGeometry.outgoing(progress: 0, direction: 1, width: width)
        XCTAssertEqual(start.offsetX, 0)
        XCTAssertEqual(start.degrees, 0)
        XCTAssertEqual(start.anchorX, 1)

        let end = GroomViewerCubeGeometry.outgoing(progress: 1, direction: 1, width: width)
        XCTAssertEqual(end.offsetX, -width)
        XCTAssertEqual(end.degrees, 90)
    }

    func testForwardIncomingFaceRisesFromRightSideToFront() {
        let start = GroomViewerCubeGeometry.incoming(progress: 0, direction: 1, width: width)
        XCTAssertEqual(start.offsetX, width)
        XCTAssertEqual(start.degrees, -90)
        XCTAssertEqual(start.anchorX, 0)

        let end = GroomViewerCubeGeometry.incoming(progress: 1, direction: 1, width: width)
        XCTAssertEqual(end.offsetX, 0)
        XCTAssertEqual(end.degrees, 0)
    }

    func testBackwardDirectionMirrorsForward() {
        let outgoing = GroomViewerCubeGeometry.outgoing(progress: 0.5, direction: -1, width: width)
        XCTAssertEqual(outgoing.offsetX, width / 2)
        XCTAssertEqual(outgoing.degrees, -45)
        XCTAssertEqual(outgoing.anchorX, 0)

        let incoming = GroomViewerCubeGeometry.incoming(progress: 0.5, direction: -1, width: width)
        XCTAssertEqual(incoming.offsetX, -width / 2)
        XCTAssertEqual(incoming.degrees, 45)
        XCTAssertEqual(incoming.anchorX, 1)
    }

    func testShadesDarkenRecedingFaceAndLightenArrivingFace() {
        XCTAssertEqual(GroomViewerCubeGeometry.outgoingShade(progress: 0), 0)
        XCTAssertEqual(
            GroomViewerCubeGeometry.outgoingShade(progress: 1),
            GroomViewerCubeGeometry.maxShadeOpacity
        )
        XCTAssertEqual(
            GroomViewerCubeGeometry.incomingShade(progress: 0),
            GroomViewerCubeGeometry.maxShadeOpacity
        )
        XCTAssertEqual(GroomViewerCubeGeometry.incomingShade(progress: 1), 0)
    }
}
