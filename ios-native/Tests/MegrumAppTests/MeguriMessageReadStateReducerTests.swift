@testable import MegrumApp
import MegrumCore
import XCTest

final class MeguriMessageReadStateReducerTests: XCTestCase {
    func testMeguriMessagesPresentationStateClearsDraftOnlyAfterSuccessfulSendAndShowsPlus() {
        var state = MeguriMessagesPresentationState()

        state.draft = "こんにちは"
        state.clearDraftAfterSend(false)

        XCTAssertEqual(state.draft, "こんにちは")

        state.showMegrumPlus()
        XCTAssertTrue(state.isShowingMegrumPlus)

        state.showInitialMegrumPlusPrompt()
        XCTAssertTrue(state.isShowingMegrumPlusPrompt)
        XCTAssertTrue(state.didShowInitialMegrumPlusPrompt)

        state.isShowingMegrumPlusPrompt = false
        state.showInitialMegrumPlusPrompt()
        XCTAssertFalse(state.isShowingMegrumPlusPrompt)

        state.showMegrumPlusPrompt()
        XCTAssertTrue(state.isShowingMegrumPlusPrompt)

        state.clearDraftAfterSend(true)

        XCTAssertEqual(state.draft, "")
    }

    func testConversationThreadsGroupByPeerAndSortUnreadFirstThenLatest() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000220")!
        let unreadPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000221")!
        let latestReadPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000222")!
        let olderPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000223")!
        let messages = [
            makeMessage(
                senderID: olderPeerID,
                recipientID: viewerID,
                body: "古い会話",
                readAt: Date(timeIntervalSince1970: 110),
                createdAt: Date(timeIntervalSince1970: 100)
            ),
            makeMessage(
                senderID: viewerID,
                recipientID: latestReadPeerID,
                body: "最新だけど既読",
                createdAt: Date(timeIntervalSince1970: 300)
            ),
            makeMessage(
                senderID: unreadPeerID,
                recipientID: viewerID,
                body: "未読",
                createdAt: Date(timeIntervalSince1970: 200),
                senderDisplayName: "未読さん",
                senderHandle: "unread"
            ),
        ]

        let threads = MeguriMessageReadStateReducer.conversationThreads(
            from: messages,
            viewerID: viewerID
        )

        XCTAssertEqual(threads.map(\.peerID), [unreadPeerID, latestReadPeerID, olderPeerID])
        XCTAssertEqual(threads.first?.displayName, "未読さん")
        XCTAssertEqual(threads.first?.handle, "unread")
        XCTAssertEqual(threads.first?.unreadCount, 1)
        XCTAssertEqual(threads.first?.lastMessagePreview, "未読")
    }

    func testConversationThreadsMergeSamePeerAcrossSourceGroomPosts() {
        // iter1226.451：ルームは1ユーザーにつき1つ。異なるグルームへの返信も同じ相手なら1ルームへ。
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000280")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000281")!
        let firstGroomPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let secondGroomPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!
        let messages = [
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                body: "1つ目",
                sourceGroomPostID: firstGroomPostID,
                createdAt: Date(timeIntervalSince1970: 100)
            ),
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                body: "2つ目",
                sourceGroomPostID: secondGroomPostID,
                createdAt: Date(timeIntervalSince1970: 200)
            ),
        ]

        let threads = MeguriMessageReadStateReducer.conversationThreads(
            from: messages,
            viewerID: viewerID
        )

        // 1ルームに統合される。sourceGroomPostID は最新メッセージ由来。
        XCTAssertEqual(threads.count, 1)
        XCTAssertEqual(threads.first?.peerID, peerID)
        XCTAssertEqual(threads.first?.sourceGroomPostID, secondGroomPostID)
        XCTAssertEqual(threads.first?.unreadCount, 2)
    }

    func testVisibleMessagesExcludeBlockedPeersWithoutDroppingOtherThreads() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000260")!
        let blockedPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000261")!
        let visiblePeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000262")!
        let messages = [
            makeMessage(senderID: blockedPeerID, recipientID: viewerID, body: "非表示"),
            makeMessage(senderID: viewerID, recipientID: visiblePeerID, body: "表示"),
        ]

        let visibleMessages = MeguriMessageReadStateReducer.visibleMessages(
            messages,
            viewerID: viewerID,
            blockedUserIDs: [blockedPeerID]
        )

        XCTAssertEqual(visibleMessages.compactMap(\.body), ["表示"])
    }

    func testLockedMessagePresentationExpandsShortTextForThreeLineBlur() {
        let expanded = MeguriLockedMessageTextPresentation.expandedText(
            "短い",
            minimumCharacterCount: 18
        )

        XCTAssertGreaterThanOrEqual(expanded.count, 18)
        XCTAssertTrue(expanded.contains("短い"))
    }

    func testUnreadIncomingCountCountsOnlyUnreadMessagesToViewer() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000224")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000225")!
        let messages = [
            makeMessage(senderID: peerID, recipientID: viewerID),
            makeMessage(senderID: peerID, recipientID: viewerID, readAt: Date(timeIntervalSince1970: 100)),
            makeMessage(senderID: viewerID, recipientID: peerID),
        ]

        XCTAssertEqual(
            MeguriMessageReadStateReducer.unreadIncomingCount(messages, viewerID: viewerID),
            1
        )
    }

    func testLockedThreadPreviewUsesPremiumLabel() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000231")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000232")!
        let messages = [
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                body: nil,
                locked: true
            )
        ]

        let threads = MeguriMessageReadStateReducer.conversationThreads(
            from: messages,
            viewerID: viewerID
        )

        XCTAssertEqual(threads.first?.lastMessagePreview, "Megrumプレミアムで表示できます")
        XCTAssertTrue(threads.first?.lastMessage.locked == true)
    }

    func testConversationThreadUsesPublicProfileWhenMeguriProfileIsLinked() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000271")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000272")!
        let messages = [
            makeMessage(senderID: peerID, recipientID: viewerID, senderDisplayName: "匿名名", senderHandle: "anon")
        ]
        let publicProfile = PublicUserProfile(
            profile: UserProfile(
                id: peerID,
                handle: "goods",
                displayName: "グッズ名",
                avatarURL: URL(string: "https://example.com/goods-avatar.jpg")
            )
        )
        let meguriProfile = MeguriProfile(
            userID: peerID,
            displayName: "匿名名",
            avatarID: "avatar_4",
            usesPublicProfile: true
        )

        let thread = try XCTUnwrap(MeguriMessageReadStateReducer.conversationThreads(
            from: messages,
            viewerID: viewerID,
            publicProfilesByUserID: [peerID: publicProfile],
            meguriProfilesByUserID: [peerID: meguriProfile]
        ).first)

        XCTAssertEqual(thread.displayName, "グッズ名")
        XCTAssertEqual(thread.handle, "goods")
        XCTAssertEqual(thread.avatarURL, URL(string: "https://example.com/goods-avatar.jpg"))
        XCTAssertNil(thread.avatarID)
        XCTAssertTrue(thread.usesPublicProfile)
    }

    /// iter1226.296: めぐりプロフィール廃止。匿名めぐりプロフィールがあっても
    /// グッズ交換側（公開）プロフィールで表示する。
    func testConversationThreadUsesPublicProfileEvenWhenMeguriProfileIsAnonymous() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000273")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000274")!
        let messages = [
            makeMessage(senderID: peerID, recipientID: viewerID, senderDisplayName: "公開名", senderHandle: "public")
        ]
        let publicProfile = PublicUserProfile(
            profile: UserProfile(
                id: peerID,
                handle: "public",
                displayName: "公開名",
                avatarURL: URL(string: "https://example.com/public-avatar.jpg")
            )
        )
        let meguriProfile = MeguriProfile(
            userID: peerID,
            displayName: "匿名名",
            avatarID: "avatar_5",
            usesPublicProfile: false
        )

        let thread = try XCTUnwrap(MeguriMessageReadStateReducer.conversationThreads(
            from: messages,
            viewerID: viewerID,
            publicProfilesByUserID: [peerID: publicProfile],
            meguriProfilesByUserID: [peerID: meguriProfile]
        ).first)

        XCTAssertEqual(thread.displayName, "公開名")
        XCTAssertEqual(thread.handle, "public")
        XCTAssertNil(thread.avatarID)
        XCTAssertEqual(thread.avatarURL, URL(string: "https://example.com/public-avatar.jpg"))
        XCTAssertTrue(thread.usesPublicProfile)
    }

    func testPendingReplyThreadCountCountsThreadsWhereLatestMessageIsIncoming() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000226")!
        let pendingUnreadPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000227")!
        let pendingReadPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000228")!
        let repliedPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000229")!
        let outgoingOnlyPeerID = UUID(uuidString: "00000000-0000-0000-0000-000000000230")!
        let messages = [
            makeMessage(
                senderID: pendingUnreadPeerID,
                recipientID: viewerID,
                body: "未返信です",
                createdAt: Date(timeIntervalSince1970: 100)
            ),
            makeMessage(
                senderID: pendingReadPeerID,
                recipientID: viewerID,
                body: "読んだけど未返信です",
                readAt: Date(timeIntervalSince1970: 125),
                createdAt: Date(timeIntervalSince1970: 120)
            ),
            makeMessage(
                senderID: repliedPeerID,
                recipientID: viewerID,
                body: "先に届いた",
                createdAt: Date(timeIntervalSince1970: 140)
            ),
            makeMessage(
                senderID: viewerID,
                recipientID: repliedPeerID,
                body: "返信済み",
                createdAt: Date(timeIntervalSince1970: 160)
            ),
            makeMessage(
                senderID: viewerID,
                recipientID: outgoingOnlyPeerID,
                body: "自分から送っただけ",
                createdAt: Date(timeIntervalSince1970: 180)
            ),
            makeMessage(
                senderID: pendingUnreadPeerID,
                recipientID: viewerID,
                body: "追加で届いた",
                createdAt: Date(timeIntervalSince1970: 200)
            ),
        ]

        XCTAssertEqual(
            MeguriMessageReadStateReducer.pendingReplyThreadCount(messages, viewerID: viewerID),
            2
        )
    }

    func testPendingReplyThreadCountMergesMultipleSourceThreadsFromSamePeer() {
        // iter1226.451：同じ相手からの複数グルーム返信は1ルームに統合され、未返信ルーム数も1。
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000282")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000283")!
        let messages = [
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                body: "1つ目",
                sourceGroomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
                createdAt: Date(timeIntervalSince1970: 100)
            ),
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                body: "2つ目",
                sourceGroomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000504")!,
                createdAt: Date(timeIntervalSince1970: 200)
            ),
        ]

        XCTAssertEqual(
            MeguriMessageReadStateReducer.pendingReplyThreadCount(messages, viewerID: viewerID),
            1
        )
    }

    func testAppendingSentMessageKeepsExistingOrderAndAddsMessageAtEnd() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000210")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000211")!
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000212")!
        let appendedID = UUID(uuidString: "00000000-0000-0000-0000-000000000213")!
        let messages = [
            makeMessage(id: firstID, senderID: peerID, recipientID: viewerID, body: "既存")
        ]
        let sentMessage = makeMessage(
            id: appendedID,
            senderID: viewerID,
            recipientID: peerID,
            body: "送信済み"
        )

        let updated = MeguriMessageReadStateReducer.appendingSentMessage(
            sentMessage,
            to: messages
        )

        XCTAssertEqual(updated.map(\.id), [firstID, appendedID])
        XCTAssertEqual(updated.last?.body, "送信済み")
    }

    func testMarkIncomingMessagesReadOnlyUpdatesUnreadMessagesFromPeerToViewer() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000203")!
        let existingReadAt = Date(timeIntervalSince1970: 100)
        let readAt = Date(timeIntervalSince1970: 200)
        let messages = [
            makeMessage(senderID: peerID, recipientID: viewerID),
            makeMessage(senderID: viewerID, recipientID: peerID),
            makeMessage(senderID: otherID, recipientID: viewerID),
            makeMessage(senderID: peerID, recipientID: viewerID, readAt: existingReadAt),
        ]

        XCTAssertTrue(
            MeguriMessageReadStateReducer.hasUnreadIncomingMessages(
                messages,
                conversationKey: MeguriMessageConversationKey(peerID: peerID),
                viewerID: viewerID
            )
        )

        let updated = MeguriMessageReadStateReducer.markIncomingMessagesRead(
            messages,
            conversationKey: MeguriMessageConversationKey(peerID: peerID),
            viewerID: viewerID,
            readAt: readAt
        )

        XCTAssertEqual(updated[0].readAt, readAt)
        XCTAssertNil(updated[1].readAt)
        XCTAssertNil(updated[2].readAt)
        XCTAssertEqual(updated[3].readAt, existingReadAt)
    }

    func testHasUnreadIncomingMessagesReturnsFalseWhenOnlyOutgoingOrAlreadyRead() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000204")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000205")!
        let readAt = Date(timeIntervalSince1970: 300)
        let messages = [
            makeMessage(senderID: viewerID, recipientID: peerID),
            makeMessage(senderID: peerID, recipientID: viewerID, readAt: readAt),
        ]

        XCTAssertFalse(
            MeguriMessageReadStateReducer.hasUnreadIncomingMessages(
                messages,
                conversationKey: MeguriMessageConversationKey(peerID: peerID),
                viewerID: viewerID
            )
        )
    }

    func testMarkIncomingMessagesReadUpdatesAllPeerMessagesRegardlessOfSource() {
        // iter1226.451：ルームは相手単位。既読化は sourceGroomPostID に関わらず相手からの全未読に及ぶ。
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000284")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000285")!
        let targetSourceID = UUID(uuidString: "00000000-0000-0000-0000-000000000505")!
        let otherSourceID = UUID(uuidString: "00000000-0000-0000-0000-000000000506")!
        let readAt = Date(timeIntervalSince1970: 500)
        let messages = [
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                sourceGroomPostID: targetSourceID
            ),
            makeMessage(
                senderID: peerID,
                recipientID: viewerID,
                sourceGroomPostID: otherSourceID
            ),
        ]

        let updated = MeguriMessageReadStateReducer.markIncomingMessagesRead(
            messages,
            conversationKey: MeguriMessageConversationKey(peerID: peerID),
            viewerID: viewerID,
            readAt: readAt
        )

        XCTAssertEqual(updated[0].readAt, readAt)
        XCTAssertEqual(updated[1].readAt, readAt)
    }

    func testMergingUpdatedReplacesOnlyReturnedMessages() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000206")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000207")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000208")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000209")!
        let messages = [
            makeMessage(id: targetID, senderID: peerID, recipientID: viewerID, body: "古い本文"),
            makeMessage(id: otherID, senderID: viewerID, recipientID: peerID, body: "そのまま"),
        ]
        let serverReadAt = Date(timeIntervalSince1970: 400)
        let serverMessage = makeMessage(
            id: targetID,
            senderID: peerID,
            recipientID: viewerID,
            body: "サーバー本文",
            readAt: serverReadAt
        )

        let updated = MeguriMessageReadStateReducer.mergingUpdated(
            messages,
            updated: [serverMessage]
        )

        XCTAssertEqual(updated[0].body, "サーバー本文")
        XCTAssertEqual(updated[0].readAt, serverReadAt)
        XCTAssertEqual(updated[1].body, "そのまま")
    }

    private func makeMessage(
        id: UUID = UUID(),
        senderID: UUID,
        recipientID: UUID,
        body: String? = "こんにちは",
        sourceGroomPostID: UUID? = nil,
        readAt: Date? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        locked: Bool = false,
        senderDisplayName: String? = nil,
        senderHandle: String? = nil
    ) -> MeguriMessage {
        MeguriMessage(
            id: id,
            senderID: senderID,
            recipientID: recipientID,
            sourceGroomPostID: sourceGroomPostID,
            messageType: .text,
            body: body,
            readAt: readAt,
            createdAt: createdAt,
            locked: locked,
            senderDisplayName: senderDisplayName,
            senderHandle: senderHandle
        )
    }
}
