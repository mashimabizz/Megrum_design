@testable import MegrumApp
import MegrumCore
import XCTest

final class GoodsEditorWishPhotoRemovalPolicyTests: XCTestCase {
    func testWishPhotoRemovalLocksWhenActivePausedOrMatchedListingUsesWish() {
        let wishID = UUID()
        let listings: [IndividualListing] = [
            listing(status: .active, wishID: wishID),
            listing(status: .paused, wishID: wishID),
            listing(status: .matched, wishID: wishID)
        ]

        XCTAssertTrue(
            GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
                itemID: wishID,
                entryKind: .wish,
                listings: listings
            )
        )
    }

    func testWishPhotoRemovalIgnoresClosedListings() {
        let wishID = UUID()

        XCTAssertFalse(
            GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
                itemID: wishID,
                entryKind: .wish,
                listings: [listing(status: .closed, wishID: wishID)]
            )
        )
    }

    func testWishPhotoRemovalDoesNotLockInventoryOrMissingItem() {
        let wishID = UUID()
        let listings = [listing(status: .active, wishID: wishID)]

        XCTAssertFalse(
            GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
                itemID: wishID,
                entryKind: .inventory,
                listings: listings
            )
        )
        XCTAssertFalse(
            GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
                itemID: nil,
                entryKind: .wish,
                listings: listings
            )
        )
    }

    private func listing(status: IndividualListingStatus, wishID: UUID) -> IndividualListing {
        let listingID = UUID()
        return IndividualListing(
            id: listingID,
            ownerID: UUID(),
            haves: [ListingItemQuantity(itemID: UUID(), quantity: 1)],
            status: status,
            options: [
                IndividualListingWishOption(
                    id: UUID(),
                    listingID: listingID,
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: wishID, quantity: 1)]
                )
            ]
        )
    }
}
