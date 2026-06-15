@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeListingSheetSelectionStateReducerTests: XCTestCase {
    func testPreparingInitialSelectionFollowsWantedLogic() {
        XCTAssertEqual(
            HomeListingSheetSelectionStateReducer.preparingInitialSelection(
                itemCount: 3,
                logic: .all
            )
            .selectedWantedIndices,
            [0, 1, 2]
        )
        XCTAssertEqual(
            HomeListingSheetSelectionStateReducer.preparingInitialSelection(
                itemCount: 3,
                logic: .one
            )
            .selectedWantedIndices,
            []
        )
    }

    func testTogglingWantedClearsOfferSelectionAndKeepsCashWhenStillSelected() {
        let state = HomeListingSheetSelectionState(
            selectedWantedIndices: [0],
            selectedOfferIndices: [1],
            cashAmountText: "1500"
        )

        let result = HomeListingSheetSelectionStateReducer.togglingWanted(
            at: 2,
            in: state,
            itemCount: 3,
            logic: .one
        )

        XCTAssertEqual(result.selectedWantedIndices, [2])
        XCTAssertEqual(result.selectedOfferIndices, [])
        XCTAssertEqual(result.cashAmountText, "1500")
    }

    func testTogglingWantedClearsCashWhenSelectionBecomesEmpty() {
        let state = HomeListingSheetSelectionState(
            selectedWantedIndices: [1],
            selectedOfferIndices: [0],
            cashAmountText: "1500"
        )

        let result = HomeListingSheetSelectionStateReducer.togglingWanted(
            at: 1,
            in: state,
            itemCount: 3,
            logic: .one
        )

        XCTAssertEqual(result.selectedWantedIndices, [])
        XCTAssertEqual(result.selectedOfferIndices, [])
        XCTAssertEqual(result.cashAmountText, "")
    }

    func testTogglingOfferFollowsOfferPolicyWithoutChangingWantedOrCash() {
        let state = HomeListingSheetSelectionState(
            selectedWantedIndices: [0, 1],
            selectedOfferIndices: [0],
            cashAmountText: "900"
        )

        let result = HomeListingSheetSelectionStateReducer.togglingOffer(
            at: 2,
            in: state,
            itemCount: 3,
            logic: .all
        )

        XCTAssertEqual(result.selectedWantedIndices, [0, 1])
        XCTAssertEqual(result.selectedOfferIndices, [0, 2])
        XCTAssertEqual(result.cashAmountText, "900")
    }
}
