import MegrumApp
import MegrumCore
import XCTest

final class GroomInteractionStateReducerTests: XCTestCase {
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
