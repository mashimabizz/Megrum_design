import MegrumApp
import MegrumCore
import XCTest

final class IndividualListingStateReducerTests: XCTestCase {
    func testUpsertingNewListingInsertsAtFront() {
        let existing = makeListing(idSuffix: "901")
        let inserted = makeListing(idSuffix: "902")

        let updated = IndividualListingStateReducer.upserting(
            inserted,
            into: [existing]
        )

        XCTAssertEqual(updated, [inserted, existing])
    }

    func testUpsertingExistingListingReplacesAndMovesToFront() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000903")!
        let original = makeListing(id: targetID, note: "古い内容")
        let other = makeListing(idSuffix: "904")
        let updatedListing = makeListing(id: targetID, note: "新しい内容")

        let updated = IndividualListingStateReducer.upserting(
            updatedListing,
            into: [other, original]
        )

        XCTAssertEqual(updated, [updatedListing, other])
    }

    func testRemovingListingKeepsOtherListingsInOrder() {
        let first = makeListing(idSuffix: "905")
        let removed = makeListing(idSuffix: "906")
        let last = makeListing(idSuffix: "907")

        let updated = IndividualListingStateReducer.removing(
            listingID: removed.id,
            from: [first, removed, last]
        )

        XCTAssertEqual(updated, [first, last])
    }

    private func makeListing(
        idSuffix: String,
        note: String? = nil
    ) -> IndividualListing {
        makeListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            note: note
        )
    }

    private func makeListing(
        id: UUID,
        note: String? = nil
    ) -> IndividualListing {
        IndividualListing(
            id: id,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000999")!,
            haves: [
                ListingItemQuantity(
                    itemID: UUID(uuidString: "00000000-0000-0000-0000-000000000998")!,
                    quantity: 1
                )
            ],
            status: .active,
            note: note
        )
    }
}
