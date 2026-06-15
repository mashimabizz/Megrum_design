import MegrumApp
import MegrumCore
import XCTest

final class MeguriMessageReadStateReducerTests: XCTestCase {
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
        body: String = "こんにちは",
        readAt: Date? = nil
    ) -> MeguriMessage {
        MeguriMessage(
            id: id,
            senderID: senderID,
            recipientID: recipientID,
            messageType: .text,
            body: body,
            readAt: readAt,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
