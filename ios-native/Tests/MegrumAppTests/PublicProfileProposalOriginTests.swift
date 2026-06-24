@testable import MegrumApp
import MegrumCore
import XCTest

final class PublicProfileProposalOriginTests: XCTestCase {
    func testStandalonePublicProfileAllowsProposalActions() {
        XCTAssertTrue(PublicProfilePresentationContext.standalone.allowsProposalActions)
    }

    func testHomeDiscoveryStackedPublicProfileDisablesProposalActions() {
        XCTAssertFalse(PublicProfilePresentationContext.stackedFromHomeDiscoverySheet.allowsProposalActions)
    }

    func testTradeChatPublicProfileDisablesProposalActionsAndDismissButton() {
        XCTAssertFalse(PublicProfilePresentationContext.tradeChat.allowsProposalActions)
        XCTAssertFalse(PublicProfilePresentationContext.tradeChat.showsDismissToolbarButton)
    }

    func testStandalonePublicProfileKeepsDismissButton() {
        XCTAssertTrue(PublicProfilePresentationContext.standalone.showsDismissToolbarButton)
    }

    func testHomeDiscoveryProfileRoutingStacksWhenSheetCanHostProfile() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000111")!

        XCTAssertEqual(
            HomeDiscoveryOwnerProfileRoutingPolicy.decision(
                for: userID,
                canPresentNestedProfile: true
            ),
            .nested(PublicProfileRoute(userID: userID))
        )
    }

    func testHomeDiscoveryProfileRoutingFallsBackToParentWhenSheetCannotHostProfile() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000112")!

        XCTAssertEqual(
            HomeDiscoveryOwnerProfileRoutingPolicy.decision(
                for: userID,
                canPresentNestedProfile: false
            ),
            .parent(userID)
        )
    }

    func testListingProposalTargetPreservesListingOriginAndReceiverGoodsOrder() throws {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let firstGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let secondGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let listingID = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        let listing = IndividualListing(
            id: listingID,
            ownerID: ownerID,
            haves: [
                ListingItemQuantity(itemID: firstGoodsID, quantity: 1),
                ListingItemQuantity(itemID: secondGoodsID, quantity: 2),
                ListingItemQuantity(itemID: firstGoodsID, quantity: 1)
            ],
            haveLogic: .all,
            status: .active
        )
        let firstGoods = GoodsItem(id: firstGoodsID, ownerID: ownerID, title: "譲るA")
        let secondGoods = GoodsItem(id: secondGoodsID, ownerID: ownerID, title: "譲るB")

        let target = try XCTUnwrap(
            ListingProposalTarget(
                listing: listing,
                goodsByID: [
                    firstGoods.id: firstGoods,
                    secondGoods.id: secondGoods
                ]
            )
        )

        XCTAssertEqual(target.id, listingID)
        XCTAssertEqual(target.listing.id, listingID)
        XCTAssertEqual(target.targetItem.id, firstGoodsID)
        XCTAssertEqual(target.receiverGoodsIDs, [firstGoodsID, secondGoodsID])
    }

    func testListingProposalTargetReturnsNilWhenNoPublicGoodsCanAnchorSheet() {
        let listing = IndividualListing(
            id: UUID(),
            ownerID: UUID(),
            haves: [
                ListingItemQuantity(itemID: UUID(), quantity: 1)
            ],
            haveLogic: .all,
            status: .active
        )

        XCTAssertNil(ListingProposalTarget(listing: listing, goodsByID: [:]))
    }
}
