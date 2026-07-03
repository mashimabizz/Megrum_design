@testable import MegrumApp
import MegrumCore
import XCTest

final class GroomInteractionStateReducerTests: XCTestCase {
    func testGroomViewerInteractionStateTracksReplyAndModerationDialogs() {
        var state = GroomViewerInteractionState()

        XCTAssertNil(state.replyBodyForSubmission(isSending: false))
        XCTAssertFalse(state.isShowingReportConfirmation)
        XCTAssertFalse(state.isShowingBlockConfirmation)

        state.replyDraft = "  近くにいます  "
        state.showReportConfirmation()
        state.showBlockConfirmation()

        XCTAssertEqual(state.trimmedReply, "近くにいます")
        XCTAssertEqual(state.replyBodyForSubmission(isSending: false), "近くにいます")
        XCTAssertNil(state.replyBodyForSubmission(isSending: true))
        XCTAssertTrue(state.isShowingReportConfirmation)
        XCTAssertTrue(state.isShowingBlockConfirmation)

        state.clearReplyAfterSend(succeeded: false)

        XCTAssertEqual(state.replyDraft, "  近くにいます  ")

        state.clearReplyAfterSend(succeeded: true)

        XCTAssertEqual(state.replyDraft, "")
    }

    func testGroomViewerLikeButtonPresentationStateTracksBurst() {
        let firstToken = UUID(uuidString: "00000000-0000-0000-0000-000000001401")!
        let secondToken = UUID(uuidString: "00000000-0000-0000-0000-000000001402")!
        var state = GroomViewerLikeButtonPresentationState()

        XCTAssertFalse(state.isBursting)
        XCTAssertEqual(state.likeIconScale, 1)

        state.startBurst(token: firstToken)

        XCTAssertTrue(state.isBursting)
        XCTAssertEqual(state.burstToken, firstToken)
        XCTAssertEqual(state.likeIconScale, 1.16)

        state.finishBurst()

        XCTAssertFalse(state.isBursting)
        XCTAssertEqual(state.burstToken, firstToken)
        XCTAssertEqual(state.likeIconScale, 1)

        state.startBurst(token: secondToken)

        XCTAssertEqual(state.burstToken, secondToken)
        XCTAssertTrue(state.isBursting)
    }

    func testMarkingViewedAddsPostID() {
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000001301")!
        let existingID = UUID(uuidString: "00000000-0000-0000-0000-000000001302")!

        let updated = GroomInteractionStateReducer.markingViewed(
            postID: postID,
            in: [existingID]
        )

        XCTAssertEqual(updated, [existingID, postID])
    }

    func testSettingLikedAddsOrRemovesPostID() {
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000001303")!
        let existingID = UUID(uuidString: "00000000-0000-0000-0000-000000001304")!

        let liked = GroomInteractionStateReducer.settingLiked(
            postID: postID,
            isLiked: true,
            in: [existingID]
        )
        let unliked = GroomInteractionStateReducer.settingLiked(
            postID: existingID,
            isLiked: false,
            in: liked
        )

        XCTAssertEqual(liked, [existingID, postID])
        XCTAssertEqual(unliked, [postID])
    }

    func testVisibleViewedIDsKeepsOnlyPostsStillInSnapshot() {
        let keptID = UUID(uuidString: "00000000-0000-0000-0000-000000001305")!
        let staleID = UUID(uuidString: "00000000-0000-0000-0000-000000001306")!
        let post = makePost(id: keptID, liked: false)

        let updated = GroomInteractionStateReducer.visibleViewedIDs(
            [keptID, staleID],
            in: [post]
        )

        XCTAssertEqual(updated, [keptID])
    }

    func testLikedIDsUsesLikedPostsFromSnapshot() {
        let likedPost = makePost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001307")!,
            liked: true
        )
        let unlikedPost = makePost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001308")!,
            liked: false
        )

        let likedIDs = GroomInteractionStateReducer.likedIDs(from: [likedPost, unlikedPost])

        XCTAssertEqual(likedIDs, [likedPost.id])
    }

    private func makePost(id: UUID, liked: Bool) -> GroomPost {
        GroomPost(
            id: id,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000001399")!,
            imageURL: URL(string: "https://example.com/groom.png")!,
            latitude: 35.0,
            longitude: 139.0,
            liked: liked
        )
    }
}
