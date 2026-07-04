import CoreGraphics
@testable import MegrumApp
import XCTest

final class MegrumTabBarAppearanceTests: XCTestCase {
    func testTabBarKeepsLabelsRaisedAboveBottomGlass() {
        XCTAssertEqual(MegrumTabBarLayoutMetrics.titleVerticalAdjustment, -8)
        XCTAssertEqual(MegrumTabBarLayoutMetrics.imageVerticalInset, 3)
    }

    func testTabBarHidesSystemBackgroundPlate() {
        XCTAssertTrue(MegrumTabBarLayoutMetrics.hidesSystemBackground)
    }

    func testMainTabOrderUsesHomeTradesMeguriInventoryWish() {
        XCTAssertEqual(MegrumTab.allCases, [.home, .trades, .meguri, .inventory, .wish])
    }

    func testTradesTabUsesSingleMessageIconAndWishUsesJapaneseTitle() {
        XCTAssertEqual(MegrumTab.trades.symbolName, "message")
        XCTAssertEqual(MegrumTab.inventory.symbolName, "rectangle.on.rectangle")
        XCTAssertEqual(MegrumTab.wish.title, "ほしいもの")
    }
}
