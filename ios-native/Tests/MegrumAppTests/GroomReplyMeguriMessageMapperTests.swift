@testable import MegrumApp
import MegrumCore
import XCTest

final class GroomReplyMeguriMessageMapperTests: XCTestCase {
    func testSentMessageKeepsReplyAndViewerFields() {
        let viewer = UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000901")!,
            handle: "megrum",
            displayName: "めぐるむ"
        )
        let recipientID = UUID(uuidString: "00000000-0000-0000-0000-000000000902")!
        let replyID = UUID(uuidString: "00000000-0000-0000-0000-000000000903")!
        let createdAt = Date(timeIntervalSince1970: 1_800)
        let reply = GroomReply(
            id: replyID,
            groomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000904")!,
            senderID: viewer.id,
            recipientID: recipientID,
            body: "グルーム返信",
            createdAt: createdAt
        )

        let message = GroomReplyMeguriMessageMapper.sentMessage(from: reply, viewer: viewer)

        XCTAssertEqual(message.senderID, viewer.id)
        XCTAssertEqual(message.recipientID, recipientID)
        XCTAssertEqual(message.sourceGroomReplyID, replyID)
        XCTAssertEqual(message.messageType, .text)
        XCTAssertEqual(message.body, "グルーム返信")
        XCTAssertEqual(message.createdAt, createdAt)
        XCTAssertEqual(message.senderDisplayName, "めぐるむ")
        XCTAssertEqual(message.senderHandle, "megrum")
        XCTAssertNil(message.readAt)
        XCTAssertFalse(message.locked)
    }
}
