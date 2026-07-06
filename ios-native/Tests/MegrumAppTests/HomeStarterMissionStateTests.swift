@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeStarterMissionStateTests: XCTestCase {
    private func makeGoods() -> GoodsItem {
        GoodsItem(id: UUID(), ownerID: UUID(), title: "サンプル")
    }

    private func makeWish() -> WishItem {
        WishItem(id: UUID(), ownerID: UUID(), title: "ほしいもの")
    }

    private func makeListing(status: IndividualListingStatus) -> IndividualListing {
        IndividualListing(id: UUID(), ownerID: UUID(), haves: [], status: status)
    }

    func testEmptyStateHasNoTaskDone() {
        let state = HomeStarterMissionState.evaluate(inventory: [], wishes: [], listings: [])

        XCTAssertFalse(state.inventoryDone)
        XCTAssertFalse(state.wishDone)
        XCTAssertFalse(state.listingDone)
        XCTAssertFalse(state.allDone)
        XCTAssertEqual(state.remainingCount, 3)
    }

    func testInventoryAndWishAndListingMarkDone() {
        let state = HomeStarterMissionState.evaluate(
            inventory: [makeGoods()],
            wishes: [makeWish()],
            listings: [makeListing(status: .active)]
        )

        XCTAssertTrue(state.inventoryDone)
        XCTAssertTrue(state.wishDone)
        XCTAssertTrue(state.listingDone)
        XCTAssertTrue(state.allDone)
        XCTAssertEqual(state.remainingCount, 0)
    }

    func testClosedListingDoesNotCountAsDone() {
        let state = HomeStarterMissionState.evaluate(
            inventory: [makeGoods()],
            wishes: [makeWish()],
            listings: [makeListing(status: .closed)]
        )

        XCTAssertFalse(state.listingDone)
        XCTAssertFalse(state.allDone)
        XCTAssertEqual(state.remainingCount, 1)
    }

    func testMatchedListingCountsAsDone() {
        let state = HomeStarterMissionState.evaluate(
            inventory: [makeGoods()],
            wishes: [makeWish()],
            listings: [makeListing(status: .matched)]
        )

        XCTAssertTrue(state.listingDone)
        XCTAssertTrue(state.allDone)
    }

    func testPartialCompletion() {
        let state = HomeStarterMissionState.evaluate(
            inventory: [makeGoods()],
            wishes: [],
            listings: []
        )

        XCTAssertTrue(state.inventoryDone)
        XCTAssertFalse(state.wishDone)
        XCTAssertFalse(state.listingDone)
        XCTAssertFalse(state.allDone)
        XCTAssertEqual(state.remainingCount, 2)
    }
}
