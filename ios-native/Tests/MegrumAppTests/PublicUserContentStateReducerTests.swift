import MegrumApp
import MegrumCore
import XCTest

final class PublicUserContentStateReducerTests: XCTestCase {
    func testStoringProfileReplacesRequestedUserAndPreservesOthers() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000402")!
        let profiles = [
            targetID: makeProfile(userID: targetID, handle: "old"),
            otherID: makeProfile(userID: otherID, handle: "other"),
        ]

        let updated = PublicUserContentStateReducer.storingProfile(
            makeProfile(userID: targetID, handle: "new"),
            for: targetID,
            in: profiles
        )

        XCTAssertEqual(updated[targetID]?.profile.handle, "new")
        XCTAssertEqual(updated[otherID]?.profile.handle, "other")
    }

    func testStoringPublicExchangeContentKeepsEmptyLoadedValuesForRequestedUser() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000403")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000404")!
        let existingGoods: [UUID: [GoodsItem]] = [otherID: []]
        let existingListings: [UUID: [IndividualListing]] = [otherID: []]

        let updatedGoods = PublicUserContentStateReducer.storingTradeGoods(
            [],
            for: targetID,
            in: existingGoods
        )
        let updatedListings = PublicUserContentStateReducer.storingIndividualListings(
            [],
            for: targetID,
            in: existingListings
        )

        XCTAssertEqual(updatedGoods[targetID]?.count, 0)
        XCTAssertEqual(updatedGoods[otherID]?.count, 0)
        XCTAssertEqual(updatedListings[targetID]?.count, 0)
        XCTAssertEqual(updatedListings[otherID]?.count, 0)
    }

    func testStoringEvaluationsReplacesRequestedUserAndPreservesOthers() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000405")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000406")!
        let evaluations = [
            targetID: [makeEvaluation(comment: "old")],
            otherID: [makeEvaluation(comment: "other")],
        ]

        let updated = PublicUserContentStateReducer.storingEvaluations(
            [makeEvaluation(comment: "new")],
            for: targetID,
            in: evaluations
        )

        XCTAssertEqual(updated[targetID]?.first?.comment, "new")
        XCTAssertEqual(updated[otherID]?.first?.comment, "other")
    }

    private func makeProfile(
        userID: UUID,
        handle: String
    ) -> PublicUserProfile {
        PublicUserProfile(
            profile: UserProfile(
                id: userID,
                handle: handle,
                displayName: handle
            )
        )
    }

    private func makeEvaluation(comment: String) -> UserEvaluation {
        UserEvaluation(
            id: UUID(),
            raterID: UUID(),
            raterHandle: "rater",
            raterDisplayName: "評価者",
            stars: 5,
            comment: comment,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
