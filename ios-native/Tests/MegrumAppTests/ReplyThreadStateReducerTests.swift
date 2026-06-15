import MegrumApp
import MegrumCore
import XCTest

final class ReplyThreadStateReducerTests: XCTestCase {
    func testReplacingBoardRepliesKeepsOtherThreadBuckets() {
        let targetThreadID = UUID(uuidString: "00000000-0000-0000-0000-000000000801")!
        let otherThreadID = UUID(uuidString: "00000000-0000-0000-0000-000000000802")!
        let replacement = makeBoardReply(idSuffix: "811", threadID: targetThreadID, body: "差し替え")
        let otherReply = makeBoardReply(idSuffix: "812", threadID: otherThreadID, body: "そのまま")
        let repliesByThreadID = [
            targetThreadID: [makeBoardReply(idSuffix: "813", threadID: targetThreadID, body: "古い返信")],
            otherThreadID: [otherReply],
        ]

        let updated = ReplyThreadStateReducer.replacingBoardReplies(
            in: repliesByThreadID,
            threadID: targetThreadID,
            replies: [replacement]
        )

        XCTAssertEqual(updated[targetThreadID], [replacement])
        XCTAssertEqual(updated[otherThreadID], [otherReply])
    }

    func testAppendingBoardReplyCreatesBucketAndPreservesOrder() {
        let threadID = UUID(uuidString: "00000000-0000-0000-0000-000000000803")!
        let first = makeBoardReply(idSuffix: "821", threadID: threadID, body: "1件目")
        let second = makeBoardReply(idSuffix: "822", threadID: threadID, body: "2件目")

        let created = ReplyThreadStateReducer.appendingBoardReply(
            first,
            to: [:],
            threadID: threadID
        )
        let appended = ReplyThreadStateReducer.appendingBoardReply(
            second,
            to: created,
            threadID: threadID
        )

        XCTAssertEqual(appended[threadID], [first, second])
    }

    func testAppendingGroomReplyCreatesBucketAndPreservesOrder() {
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000804")!
        let first = makeGroomReply(idSuffix: "831", postID: postID, body: "1件目")
        let second = makeGroomReply(idSuffix: "832", postID: postID, body: "2件目")

        let created = ReplyThreadStateReducer.appendingGroomReply(
            first,
            to: [:],
            postID: postID
        )
        let appended = ReplyThreadStateReducer.appendingGroomReply(
            second,
            to: created,
            postID: postID
        )

        XCTAssertEqual(appended[postID], [first, second])
    }

    private func makeBoardReply(
        idSuffix: String,
        threadID: UUID,
        body: String
    ) -> BoardReply {
        BoardReply(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            threadID: threadID,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000000899")!,
            body: body,
            createdAt: Date(timeIntervalSince1970: Double(idSuffix) ?? 0)
        )
    }

    private func makeGroomReply(
        idSuffix: String,
        postID: UUID,
        body: String
    ) -> GroomReply {
        GroomReply(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            groomPostID: postID,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000898")!,
            recipientID: UUID(uuidString: "00000000-0000-0000-0000-000000000897")!,
            body: body,
            createdAt: Date(timeIntervalSince1970: Double(idSuffix) ?? 0)
        )
    }
}
