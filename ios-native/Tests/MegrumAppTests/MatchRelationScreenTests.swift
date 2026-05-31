@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class MatchRelationScreenTests: XCTestCase {
    func testSelectableSenderGoodsKeepsOnlyTradeableInventory() {
        let viewerID = uuid(1)
        let active = goods(id: 10, ownerID: viewerID, status: .active)
        let reserved = goods(id: 11, ownerID: viewerID, status: .reserved)
        let keep = goods(id: 12, ownerID: viewerID, status: .keep)
        let traded = goods(id: 13, ownerID: viewerID, status: .traded)
        let archived = goods(id: 14, ownerID: viewerID, status: .archived)

        let result = MatchRelationComposer.selectableSenderGoods(from: [active, reserved, keep, traded, archived])

        XCTAssertEqual(result.map(\.id), [active.id, reserved.id])
    }

    func testPartnerListingRendersCandidateGoodsInsideRelationTree() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let expected = goods(id: 30, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let other = goods(id: 31, ownerID: viewerID, groupID: groupID, goodsTypeID: uuid(22))
        let partnerHave = goods(id: 32, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(40),
            ownerID: partnerID,
            haves: [ListingItemQuantity(itemID: partnerHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(41),
                    listingID: uuid(40),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: expected.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [],
            partnerListings: [listing],
            senderGoods: [other, expected],
            partnerGoods: [partnerHave],
            highlightedItemID: partnerHave.id
        )

        XCTAssertEqual(details.count, 1)
        XCTAssertFalse(details[0].isMyListing)
        XCTAssertEqual(details[0].options[0].wishes[0].candidates.map(\.item.id), [expected.id])
    }

    func testOwnListingInitialSelectionAggregatesPartnerCandidatesWithoutChoosingListingItself() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 50, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let target = goods(id: 60, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let listing = IndividualListing(
            id: uuid(70),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(71),
                    listingID: uuid(70),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: target.id, quantity: 1)],
                    logic: .all,
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

        let candidates = MatchRelationComposer.initialCandidateSelection(for: details, highlightedItemID: target.id)
        let haves = MatchRelationComposer.initialHaveSelection(for: details, highlightedItemID: target.id)
        let aggregate = MatchRelationComposer.aggregateSelection(
            details: details,
            selectedCandidateIDsByListingID: candidates,
            selectedHaveIDsByListingID: haves
        )

        XCTAssertEqual(aggregate.referencedListingIDs, [listing.id])
        XCTAssertEqual(aggregate.senderIDs, [ownHave.id])
        XCTAssertEqual(aggregate.receiverIDs, [target.id])
    }

    func testAggregateCanIncludeOwnAndPartnerListingsAtTheSameTime() {
        let viewerID = uuid(1)
        let partnerID = uuid(2)
        let groupID = uuid(20)
        let typeID = uuid(21)
        let ownHave = goods(id: 80, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let myCandidateForPartner = goods(id: 81, ownerID: viewerID, groupID: groupID, goodsTypeID: typeID)
        let partnerHave = goods(id: 82, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)
        let partnerCandidateForMe = goods(id: 83, ownerID: partnerID, groupID: groupID, goodsTypeID: typeID)

        let ownListing = IndividualListing(
            id: uuid(90),
            ownerID: viewerID,
            haves: [ListingItemQuantity(itemID: ownHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(91),
                    listingID: uuid(90),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: partnerCandidateForMe.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )
        let partnerListing = IndividualListing(
            id: uuid(92),
            ownerID: partnerID,
            haves: [ListingItemQuantity(itemID: partnerHave.id, quantity: 1)],
            options: [
                IndividualListingWishOption(
                    id: uuid(93),
                    listingID: uuid(92),
                    position: 1,
                    wishes: [ListingItemQuantity(itemID: myCandidateForPartner.id, quantity: 1)],
                    wishGroupID: groupID,
                    wishGoodsTypeID: typeID
                )
            ]
        )

        let details = MatchRelationComposer.buildRelationDetails(
            ownListings: [ownListing],
            partnerListings: [partnerListing],
            senderGoods: [ownHave, myCandidateForPartner],
            partnerGoods: [partnerHave, partnerCandidateForMe],
            highlightedItemID: partnerHave.id
        )
        let candidates: [UUID: Set<UUID>] = [
            ownListing.id: [partnerCandidateForMe.id],
            partnerListing.id: [myCandidateForPartner.id]
        ]
        let haves = MatchRelationComposer.initialHaveSelection(for: details, highlightedItemID: partnerHave.id)
        let aggregate = MatchRelationComposer.aggregateSelection(
            details: details,
            selectedCandidateIDsByListingID: candidates,
            selectedHaveIDsByListingID: haves
        )

        XCTAssertEqual(Set(aggregate.referencedListingIDs), [ownListing.id, partnerListing.id])
        XCTAssertEqual(Set(aggregate.senderIDs), [ownHave.id, myCandidateForPartner.id])
        XCTAssertEqual(Set(aggregate.receiverIDs), [partnerCandidateForMe.id, partnerHave.id])
    }

    private func goods(
        id: Int,
        ownerID: UUID,
        status: GoodsEntryStatus? = .active,
        groupID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        goodsTypeID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
    ) -> GoodsItem {
        GoodsItem(
            id: uuid(id),
            ownerID: ownerID,
            kind: .inventory,
            status: status,
            groupID: groupID,
            goodsTypeID: goodsTypeID,
            title: "item-\(id)"
        )
    }

    private func uuid(_ suffix: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", suffix))!
    }
}
