@testable import MegrumApp
import MegrumCore
import XCTest

final class GroomPostLocalMutationTests: XCTestCase {
    func testSettingLikedAdjustsTargetPostOnlyAndClampsCount() {
        let target = makePost(idSuffix: "701", authorSuffix: "801", liked: false, likeCount: 0)
        let other = makePost(idSuffix: "702", authorSuffix: "802", liked: false, likeCount: 3)

        let liked = GroomPostLocalMutation.settingLiked(
            postID: target.id,
            isLiked: true,
            adjustsCount: true,
            in: [target, other]
        )
        let unliked = GroomPostLocalMutation.settingLiked(
            postID: target.id,
            isLiked: false,
            adjustsCount: true,
            in: liked
        )

        XCTAssertEqual(liked.first?.liked, true)
        XCTAssertEqual(liked.first?.likeCount, 1)
        XCTAssertEqual(liked.last, other)
        XCTAssertEqual(unliked.first?.liked, false)
        XCTAssertEqual(unliked.first?.likeCount, 0)
    }

    func testRemovingAuthorFiltersMatchingPosts() {
        let authorID = UUID(uuidString: "00000000-0000-0000-0000-000000000803")!
        let ownPost = makePost(idSuffix: "703", authorID: authorID)
        let otherPost = makePost(idSuffix: "704", authorSuffix: "804")

        let filtered = GroomPostLocalMutation.removing(authorID: authorID, from: [ownPost, otherPost])

        XCTAssertEqual(filtered, [otherPost])
    }

    func testRemovingPostIDFiltersOnlyTargetPost() {
        let authorID = UUID(uuidString: "00000000-0000-0000-0000-000000000803")!
        let target = makePost(idSuffix: "703", authorID: authorID)
        let sameAuthorOtherPost = makePost(idSuffix: "704", authorID: authorID)
        let otherAuthorPost = makePost(idSuffix: "705", authorSuffix: "805")

        let filtered = GroomPostLocalMutation.removing(
            postID: target.id,
            from: [target, sameAuthorOtherPost, otherAuthorPost]
        )

        XCTAssertEqual(filtered, [sameAuthorOtherPost, otherAuthorPost])
    }

    func testFirstPostSearchesCollectionsInOrder() {
        let first = makePost(idSuffix: "705", authorSuffix: "805")
        let second = makePost(idSuffix: "706", authorSuffix: "806")

        let found = GroomPostLocalMutation.firstPost(
            id: second.id,
            in: [],
            [first],
            [second]
        )

        XCTAssertEqual(found, second)
    }

    private func makePost(
        idSuffix: String,
        authorSuffix: String = "899",
        liked: Bool = false,
        likeCount: Int = 0
    ) -> GroomPost {
        makePost(
            idSuffix: idSuffix,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000\(authorSuffix)")!,
            liked: liked,
            likeCount: likeCount
        )
    }

    private func makePost(
        idSuffix: String,
        authorID: UUID,
        liked: Bool = false,
        likeCount: Int = 0
    ) -> GroomPost {
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            authorID: authorID,
            imageURL: URL(string: "https://example.com/groom-\(idSuffix).jpg")!,
            latitude: 35.0,
            longitude: 139.0,
            likeCount: likeCount,
            liked: liked
        )
    }
}
