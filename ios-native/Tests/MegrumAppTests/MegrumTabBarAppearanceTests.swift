import CoreGraphics
@testable import MegrumApp
import XCTest

final class MegrumTabBarAppearanceTests: XCTestCase {
    func testTabBarKeepsLabelsRaisedAboveBottomGlass() {
        XCTAssertEqual(MegrumTabBarLayoutMetrics.titleVerticalAdjustment, -4)
    }

    func testTabBarHidesSystemBackgroundPlate() {
        XCTAssertTrue(MegrumTabBarLayoutMetrics.hidesSystemBackground)
    }
}
