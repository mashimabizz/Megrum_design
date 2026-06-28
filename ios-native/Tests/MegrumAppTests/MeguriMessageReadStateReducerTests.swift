import MegrumApp
import MegrumCore
import XCTest

final class MeguriMessageReadStateReducerTests: XCTestCase {
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

        XCTAssertEqual(threads.first?.lastMessagePreview, "Megrum プレミアムで表示できます")
        XCTAssertTrue(threads.first?.lastMessage.locked == true)
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
                peerID: peerID,
                viewerID: viewerID
            )
        )

        let updated = MeguriMessageReadStateReducer.markIncomingMessagesRead(
            messages,
            peerID: peerID,
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
                peerID: peerID,
                viewerID: viewerID
            )
        )
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
