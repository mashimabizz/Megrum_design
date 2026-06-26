@testable import MegrumApp
import MegrumCore
import XCTest

final class MegrumPlusAccessPolicyTests: XCTestCase {
    func testFreeUsersCanCreateUpToThreeCountedIndividualListings() {
        let listings = [
            listing(status: .active),
            listing(status: .paused),
            listing(status: .matched),
            listing(status: .closed)
        ]

        XCTAssertEqual(MegrumPlusAccessPolicy.activeIndividualListingCount(listings), 3)
        XCTAssertFalse(
            MegrumPlusAccessPolicy.canCreateIndividualListing(
                listings: listings,
                subscriptionState: .free
            )
        )
    }

    func testMegrumPlusUsersCanCreateUnlimitedIndividualListings() {
        let listings = (0..<5).map { _ in listing(status: .active) }
        let subscriptionState = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .megrumPlus, isActive: true, source: .subscription)
            ]
        )

        XCTAssertTrue(
            MegrumPlusAccessPolicy.canCreateIndividualListing(
                listings: listings,
                subscriptionState: subscriptionState
            )
        )
    }

    func testGroomArchiveRequestLimitOnlyCapsFreeUsers() {
        let paidState = UserSubscriptionState(
            entitlements: [
                UserEntitlement(key: .megrumPlus, isActive: true, source: .subscription)
            ]
        )

        XCTAssertEqual(
            MegrumPlusAccessPolicy.groomArchiveRequestLimit(
                requestedLimit: 120,
                subscriptionState: .free
            ),
            10
        )
        XCTAssertEqual(
            MegrumPlusAccessPolicy.groomArchiveRequestLimit(
                requestedLimit: 120,
                subscriptionState: paidState
            ),
            120
        )
    }

    private func listing(status: IndividualListingStatus) -> IndividualListing {
        IndividualListing(
            id: UUID(),
            ownerID: UUID(),
            haves: [],
            status: status
        )
    }
}
