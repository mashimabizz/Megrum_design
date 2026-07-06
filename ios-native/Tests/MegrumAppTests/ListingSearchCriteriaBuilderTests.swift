import Foundation
import MegrumCore
import XCTest
@testable import MegrumApp

final class ListingSearchCriteriaBuilderTests: XCTestCase {
    private let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000A01")!
    private let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000A02")!
    private let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000A03")!

    func testWishOptionMapsWishFieldsIntoCriteria() {
        let wish = WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000B01")!,
            ownerID: UUID(),
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            title: "ジミン トレカ",
            tags: [GoodsTag(id: UUID(), name: "READY TO BE")]
        )
        let listing = makeListing(options: [
            IndividualListingWishOption(
                id: UUID(),
                listingID: UUID(),
                position: 1,
                wishes: [ListingItemQuantity(itemID: wish.id)]
            )
        ])

        let criteria = ListingSearchCriteriaBuilder.criteria(for: listing, wishes: [wish])

        XCTAssertEqual(criteria.groupIDs, [groupID])
        XCTAssertEqual(criteria.memberIDs, [memberID])
        XCTAssertEqual(criteria.goodsTypeIDs, [goodsTypeID])
        XCTAssertEqual(criteria.tagNames, ["READY TO BE"])
        XCTAssertFalse(criteria.wantsCashOK)
    }

    func testConditionAndCashOptionsCombine() {
        let listing = makeListing(options: [
            IndividualListingWishOption(
                id: UUID(),
                listingID: UUID(),
                position: 1,
                wishes: [],
                wishGroupID: groupID,
                wishGoodsTypeID: goodsTypeID,
                wishMemberIDs: [memberID],
                wishSeriesNames: ["東京2023"]
            ),
            IndividualListingWishOption(
                id: UUID(),
                listingID: UUID(),
                position: 2,
                wishes: [],
                isCashOffer: true,
                cashAmount: 1500
            )
        ])

        let criteria = ListingSearchCriteriaBuilder.criteria(for: listing, wishes: [])

        XCTAssertEqual(criteria.groupIDs, [groupID])
        XCTAssertEqual(criteria.memberIDs, [memberID])
        XCTAssertEqual(criteria.tagNames, ["東京2023"])
        XCTAssertTrue(criteria.wantsCashOK)
    }

    func testExcludedMembersAreNotAddedToCriteria() {
        let listing = makeListing(options: [
            IndividualListingWishOption(
                id: UUID(),
                listingID: UUID(),
                position: 1,
                wishes: [],
                wishGroupID: groupID,
                wishMemberIDs: [memberID],
                excludesWishMembers: true
            )
        ])

        let criteria = ListingSearchCriteriaBuilder.criteria(for: listing, wishes: [])

        XCTAssertTrue(criteria.memberIDs.isEmpty)
        XCTAssertEqual(criteria.groupIDs, [groupID])
    }

    private func makeListing(options: [IndividualListingWishOption]) -> IndividualListing {
        IndividualListing(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000C01")!,
            ownerID: UUID(),
            haves: [],
            haveLogic: .one,
            haveMinimumCount: 1,
            status: .active,
            note: nil,
            options: options
        )
    }
}
