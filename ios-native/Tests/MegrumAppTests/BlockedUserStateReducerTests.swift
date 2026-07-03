@testable import MegrumApp
import MegrumCore
import XCTest

final class BlockedUserStateReducerTests: XCTestCase {
    func testBlockedUsersContextSeparatesExchangeAndMeguriCopy() {
        XCTAssertEqual(BlockedUsersContext.exchange.navigationTitle, "グッズ交換でブロックした人")
        XCTAssertEqual(BlockedUsersContext.meguri.navigationTitle, "めぐりでブロックした人")
        XCTAssertTrue(
            BlockedUsersContext.meguri
                .unblockConfirmationMessage(for: "相手")
                .contains("めぐりでブロックした人")
        )
    }

    func testBlockedUsersPresentationStateTracksPendingUnblockUser() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000307")!
        let user = makeBlockedUser(userID: userID, handle: "blocked")
        var state = BlockedUsersPresentationState()

        state.requestUnblock(user)

        XCTAssertTrue(state.isShowingUnblockDialog)
        XCTAssertEqual(state.userPendingUnblock, user)
        XCTAssertEqual(state.pendingUnblockUserID, userID)

        state.clearPendingUnblock()

        XCTAssertNil(state.userPendingUnblock)
        XCTAssertNil(state.pendingUnblockUserID)
        XCTAssertTrue(state.isShowingUnblockDialog)
    }

    func testRemovingBlockedUserRemovesOnlyMatchingUserIDAndKeepsOrder() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        let removedID = UUID(uuidString: "00000000-0000-0000-0000-000000000302")!
        let lastID = UUID(uuidString: "00000000-0000-0000-0000-000000000303")!
        let blockedUsers = [
            makeBlockedUser(userID: firstID, handle: "first"),
            makeBlockedUser(userID: removedID, handle: "removed"),
            makeBlockedUser(userID: lastID, handle: "last"),
        ]

        let updated = BlockedUserStateReducer.removing(
            userID: removedID,
            from: blockedUsers
        )

        XCTAssertEqual(updated.map(\.userID), [firstID, lastID])
        XCTAssertEqual(updated.map(\.handle), ["first", "last"])
    }

    func testRemovingMissingBlockedUserKeepsListUnchanged() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000304")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000305")!
        let blockedUsers = [
            makeBlockedUser(userID: firstID, handle: "first"),
            makeBlockedUser(userID: secondID, handle: "second"),
        ]

        let updated = BlockedUserStateReducer.removing(
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000306")!,
            from: blockedUsers
        )

        XCTAssertEqual(updated, blockedUsers)
    }

    private func makeBlockedUser(
        userID: UUID,
        handle: String
    ) -> BlockedUser {
        BlockedUser(
            userID: userID,
            handle: handle,
            displayName: handle,
            blockedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
