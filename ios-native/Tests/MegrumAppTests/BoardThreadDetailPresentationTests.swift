import MegrumCore
@testable import MegrumApp
import XCTest

final class BoardThreadDetailPresentationTests: XCTestCase {
    func testBoardThreadReplyComposerStateTrimsBlocksAndClearsOnlyAfterSuccess() {
        var state = BoardThreadReplyComposerState()

        XCTAssertNil(state.replyBodyForSubmission(isSending: false))

        state.draftReply = "  いま北口です  "

        XCTAssertEqual(state.trimmedReply, "いま北口です")
        XCTAssertEqual(state.replyBodyForSubmission(isSending: false), "いま北口です")
        XCTAssertNil(state.replyBodyForSubmission(isSending: true))

        state.clearDraftAfterSend(succeeded: false)

        XCTAssertEqual(state.draftReply, "  いま北口です  ")

        state.clearDraftAfterSend(succeeded: true)

        XCTAssertEqual(state.draftReply, "")
    }

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

    func testThreadBodyAppearsAsOpeningChatMessageWithReactions() {
        let authorID = uuid("001")
        let viewerID = uuid("003")
        let thread = BoardThread(
            id: uuid("101"),
            authorID: authorID,
            title: "近くにいますか？",
            body: "入口前にいます",
            audience: .nearby3km,
            createdAt: Date(timeIntervalSince1970: 1_000),
            goodReactionCount: 3,
            badReactionCount: 1,
            viewerReaction: .good
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: [],
            viewer: UserProfile(id: viewerID, handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [:],
            meguriProfilesByUserID: [:],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_060))

        XCTAssertEqual(presentation.chatMessages.count, 1)
        XCTAssertEqual(presentation.chatMessages[0].target, .thread(thread.id))
        XCTAssertEqual(presentation.chatMessages[0].body, "入口前にいます")
        XCTAssertEqual(presentation.chatMessages[0].goodReactionCount, 3)
        XCTAssertEqual(presentation.chatMessages[0].badReactionCount, 1)
        XCTAssertEqual(presentation.chatMessages[0].viewerReaction, .good)
    }

    func testThreadThumbnailIsNotDisplayedAsOpeningChatMessageImage() {
        let thread = BoardThread(
            id: uuid("101"),
            authorID: uuid("001"),
            title: "近くにいますか？",
            body: "入口前にいます",
            audience: .nearby3km,
            imageURLs: [URL(string: "https://example.com/thread.jpg")!]
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: [],
            viewer: UserProfile(id: uuid("003"), handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [:],
            meguriProfilesByUserID: [:],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_060))

        XCTAssertEqual(presentation.chatMessages[0].body, "入口前にいます")
        XCTAssertTrue(presentation.chatMessages[0].imageURLs.isEmpty)
    }

    func testReplyImageAppearsAsChatMessageImage() {
        let thread = BoardThread(
            id: uuid("101"),
            authorID: uuid("001"),
            title: "近くにいますか？",
            body: "入口前にいます",
            audience: .nearby3km
        )
        let imageURL = URL(string: "https://example.com/reply.jpg")!
        let reply = BoardReply(
            id: uuid("201"),
            threadID: thread.id,
            authorID: uuid("003"),
            body: "",
            imageURLs: [imageURL],
            imagePaths: ["reply.jpg"]
        )

        let presentation = BoardThreadDetailPresentationBuilder(
            thread: thread,
            replies: [reply],
            viewer: UserProfile(id: uuid("003"), handle: "viewer", displayName: "閲覧者"),
            profilesByUserID: [:],
            meguriProfilesByUserID: [:],
            grooms: []
        )
        .makePresentation(now: Date(timeIntervalSince1970: 1_060))

        XCTAssertEqual(presentation.chatMessages[1].target, .reply(reply.id))
        XCTAssertEqual(presentation.chatMessages[1].imageURLs, [imageURL])
        XCTAssertEqual(presentation.chatMessages[1].body, "")
    }

    func testBoardMessageReactionOptimisticUpdateSwitchesCounts() {
        let threadID = uuid("101")
        let replyID = uuid("201")
        let thread = BoardThread(
            id: threadID,
            authorID: uuid("001"),
            title: "近くにいますか？",
            body: "入口前です",
            audience: .nearby3km,
            goodReactionCount: 2,
            badReactionCount: 0,
            viewerReaction: .good
        )
        let reply = BoardReply(
            id: replyID,
            threadID: threadID,
            authorID: uuid("002"),
            body: "います",
            goodReactionCount: 0,
            badReactionCount: 1,
            viewerReaction: .bad
        )

        let updatedThreads = ReplyThreadStateReducer.settingBoardThreadReaction(
            .bad,
            threadID: threadID,
            in: [thread]
        )
        XCTAssertEqual(updatedThreads[0].goodReactionCount, 1)
        XCTAssertEqual(updatedThreads[0].badReactionCount, 1)
        XCTAssertEqual(updatedThreads[0].viewerReaction, .bad)

        let updatedReplies = ReplyThreadStateReducer.settingBoardReplyReaction(
            nil,
            replyID: replyID,
            in: [threadID: [reply]]
        )
        XCTAssertEqual(updatedReplies[threadID]?[0].goodReactionCount, 0)
        XCTAssertEqual(updatedReplies[threadID]?[0].badReactionCount, 0)
        XCTAssertNil(updatedReplies[threadID]?[0].viewerReaction)
    }

    private func uuid(_ suffix: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000\(suffix)")!
    }
}
