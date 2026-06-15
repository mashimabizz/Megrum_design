@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class MatchRelationSelectionStateReducerTests: XCTestCase {
    func testTogglingCandidateAddsAndRemovesListingKeyWhenEmpty() {
        let listingID = uuid(1)
        let candidateID = uuid(2)

        let selected = MatchRelationSelectionStateReducer.togglingCandidate(
            listingID: listingID,
            candidateID: candidateID,
            in: MatchRelationSelectionState()
        )

        XCTAssertEqual(selected.selectedCandidateIDsByListingID, [listingID: [candidateID]])

        let deselected = MatchRelationSelectionStateReducer.togglingCandidate(
            listingID: listingID,
            candidateID: candidateID,
            in: selected
        )

        XCTAssertEqual(deselected.selectedCandidateIDsByListingID, [:])
    }

    func testTogglingHavePreservesListingKeyWhenSelectionBecomesEmpty() {
        let listingID = uuid(10)
        let haveID = uuid(11)

        let selected = MatchRelationSelectionStateReducer.togglingHave(
            listingID: listingID,
            haveID: haveID,
            in: MatchRelationSelectionState()
        )

        XCTAssertEqual(selected.selectedHaveIDsByListingID, [listingID: [haveID]])

        let deselected = MatchRelationSelectionStateReducer.togglingHave(
            listingID: listingID,
            haveID: haveID,
            in: selected
        )

        XCTAssertEqual(deselected.selectedHaveIDsByListingID, [listingID: []])
    }

    func testResettingCandidatesKeepsHaveSelection() {
        let listingID = uuid(20)
        let state = MatchRelationSelectionState(
            selectedCandidateIDsByListingID: [listingID: [uuid(21)]],
            selectedHaveIDsByListingID: [listingID: [uuid(22)]]
        )

        let result = MatchRelationSelectionStateReducer.resettingCandidates(in: state)

        XCTAssertEqual(result.selectedCandidateIDsByListingID, [:])
        XCTAssertEqual(result.selectedHaveIDsByListingID, [listingID: [uuid(22)]])
    }

    func testSeedingSkipsExistingCandidateSelectionUnlessForced() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 30, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let target = goods(id: 31, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(40),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(41),
                    listingID: uuid(40),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: target.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )
        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [listing],
            partnerListings: [],
            senderGoods: [ownHave],
            partnerGoods: [target],
            highlightedItemID: target.id
        )
        let existing = MatchRelationSelectionState(
            selectedCandidateIDsByListingID: [listing.id: [uuid(99)]],
            selectedHaveIDsByListingID: [:]
        )

        let unforced = MatchRelationSelectionStateReducer.seedingInitialSelection(
            in: existing,
            details: details,
            highlightedItemID: target.id,
            force: false
        )
        let forced = MatchRelationSelectionStateReducer.seedingInitialSelection(
            in: existing,
            details: details,
            highlightedItemID: target.id,
            force: true
        )

        XCTAssertEqual(unforced.selectedCandidateIDsByListingID, [listing.id: [uuid(99)]])
        XCTAssertEqual(forced.selectedCandidateIDsByListingID, [listing.id: [target.id]])
    }

    private func goods(
        id: Int,
        ownerID: UUID,
        groupID: UUID,
        goodsTypeID: UUID
    ) -> GoodsItem {
        GoodsItem(
            id: uuid(id),
            ownerID: ownerID,
            kind: .inventory,
            status: .active,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "item-\(id)"
        )
    }

    private func uuid(_ suffix: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", suffix))!
    }
}
