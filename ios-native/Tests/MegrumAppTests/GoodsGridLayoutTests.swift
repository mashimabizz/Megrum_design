@testable import MegrumApp
import XCTest

final class GoodsGridLayoutTests: XCTestCase {
    func testLayoutNormalizesColumnsToSupportedRange() {
        XCTAssertEqual(GoodsGridLayout(columns: 2).columns, 3)
        XCTAssertEqual(GoodsGridLayout(columns: 3).columns, 3)
        XCTAssertEqual(GoodsGridLayout(columns: 5).columns, 5)
        XCTAssertEqual(GoodsGridLayout(columns: 6).columns, 5)
    }

    func testLayoutCyclesThroughThreeFourFiveColumns() {
        XCTAssertEqual(GoodsGridLayout(columns: 3).nextColumns, 4)
        XCTAssertEqual(GoodsGridLayout(columns: 4).nextColumns, 5)
        XCTAssertEqual(GoodsGridLayout(columns: 5).nextColumns, 3)
    }

    func testSkeletonTileCountTracksTwoRowsOfCurrentColumns() {
        XCTAssertEqual(GoodsGridLayout(columns: 3).skeletonTileCount, 6)
        XCTAssertEqual(GoodsGridLayout(columns: 4).skeletonTileCount, 8)
        XCTAssertEqual(GoodsGridLayout(columns: 5).skeletonTileCount, 10)
    }
}
