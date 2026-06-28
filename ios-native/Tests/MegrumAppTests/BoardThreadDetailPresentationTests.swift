import MegrumCore
@testable import MegrumApp
import XCTest

final class BoardThreadDetailPresentationTests: XCTestCase {
    func testAnonymousBoardRepliesDoNotExposePublicProfiles() {
        let authorID = uuid("001")
        let replyAuthorID = uuid("002")
        let viewerID = uuid("003")
        let thread = BoardThread(
            id: uuid("101"),
            authorID: authorID,
            title: "物販列どのくらい？",
            body: "北口側が動いています",
            audience: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: "東京都",
            createdAt: Date(timeIntervalSince1970: 1_000),
            anonymousDisplayName: "現場の人",
            anonymousAvatarID: "avatar_1"
        )
        let replies = [
            BoardReply(
                id: uuid("201"),
                threadID: thread.id,
                authorID: replyAuthorID,
                body: "今は20分くらいです",
                createdAt: Date(timeIntervalSince1970: 1_100)
            ),
            BoardReply(
                id: uuid("202"),
                threadID: thread.id,
                authorID: replyAuthorID,
                body: "列が少し伸びました",
                createdAt: Date(timeIntervalSince1970: 1_200)
            ),
            BoardReply(
                id: uuid("203"),
                threadID: thread.id,
                authorID: authorID,
                body: "ありがとう",
                createdAt: Date(timeIntervalSince1970: 1_300)
            )
        ]
        let publicProfile = PublicUserProfile(
            profile: UserProfile(
                id: replyAuthorID,
                handle: "real_user",
                displayName: "実名ユーザー",
                avatarURL: URL(string: "https://example.com/profile.jpg")
            )
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: replies,
            viewer: UserProfile(id: viewerID, handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [replyAuthorID: publicProfile],
            meguriProfilesByUserID: [:],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_400))

        XCTAssertEqual(presentation.authorName, "現場の人")
        XCTAssertNil(presentation.authorAvatarURL)
        XCTAssertEqual(presentation.replies[0].displayName, "yuna")
        XCTAssertEqual(presentation.replies[1].displayName, "yuna")
        XCTAssertNil(presentation.replies[0].avatarURL)
        XCTAssertNil(presentation.replies[1].avatarURL)
        XCTAssertNotEqual(presentation.replies[0].displayName, "実名ユーザー")
        XCTAssertEqual(presentation.replies[2].displayName, "現場の人")
        XCTAssertNil(presentation.replies[2].avatarURL)
    }

    func testAnonymousBoardAuthorAvatarOnlyDoesNotExposePublicName() {
        let authorID = uuid("001")
        let thread = BoardThread(
            id: uuid("101"),
            authorID: authorID,
            title: "終演後どこにいますか？",
            body: "駅前が混んでいます",
            audience: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: "東京都",
            createdAt: Date(timeIntervalSince1970: 1_000),
            anonymousDisplayName: nil,
            anonymousAvatarID: "avatar_2"
        )
        let publicProfile = PublicUserProfile(
            profile: UserProfile(
                id: authorID,
                handle: "real_author",
                displayName: "公開名",
                avatarURL: URL(string: "https://example.com/author.jpg")
            )
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: [],
            viewer: UserProfile(id: uuid("003"), handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [authorID: publicProfile],
            meguriProfilesByUserID: [:],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_400))

        XCTAssertEqual(presentation.authorName, "匿名さん")
        XCTAssertNil(presentation.authorAvatarURL)
        XCTAssertNotEqual(presentation.authorName, "公開名")
    }

    func testMeguriProfileIsUsedBeforePublicProfile() {
        let authorID = uuid("001")
        let thread = BoardThread(
            id: uuid("101"),
            authorID: authorID,
            title: "近くにいますか？",
            body: "入口前です",
            audience: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: "東京都",
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let publicProfile = PublicUserProfile(
            profile: UserProfile(
                id: authorID,
                handle: "real_author",
                displayName: "公開名",
                avatarURL: URL(string: "https://example.com/author.jpg")
            )
        )
        let meguriProfile = MeguriProfile(
            userID: authorID,
            displayName: "めぐり名",
            avatarID: "avatar_4",
            lastChangedAt: Date(timeIntervalSince1970: 900)
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: [],
            viewer: UserProfile(id: uuid("003"), handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [authorID: publicProfile],
            meguriProfilesByUserID: [authorID: meguriProfile],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_400))

        XCTAssertEqual(presentation.authorName, "めぐり名")
        XCTAssertEqual(presentation.authorAvatarID, "avatar_4")
        XCTAssertNil(presentation.authorAvatarURL)
    }

    private func uuid(_ suffix: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000\(suffix)")!
    }
}
