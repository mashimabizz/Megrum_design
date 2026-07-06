import XCTest
@testable import MegrumApp

final class ChatReplyQuoteFormatterTests: XCTestCase {
    func testComposeAndParseRoundTrip() {
        let messageID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let target = ChatReplyTarget(
            messageID: messageID,
            senderID: senderID,
            senderName: "みち",
            avatarID: nil,
            avatarURL: nil,
            initial: "み",
            body: "誘ってくれてありがとう！\n楽しかったです"
        )
        let composed = ChatReplyQuoteFormatter.compose(reply: target, body: "こちらこそ！")

        let parsed = ChatReplyQuoteFormatter.parse(composed)
        XCTAssertEqual(parsed.quote?.messageID, messageID)
        XCTAssertEqual(parsed.quote?.senderID, senderID)
        XCTAssertEqual(parsed.quote?.senderName, "みち")
        XCTAssertEqual(parsed.quote?.preview, "誘ってくれてありがとう！ 楽しかったです")
        XCTAssertEqual(parsed.text, "こちらこそ！")
        XCTAssertEqual(ChatReplyQuoteFormatter.copyText(of: composed), "こちらこそ！")
    }

    func testParseReturnsPlainBodyWhenNoQuote() {
        let parsed = ChatReplyQuoteFormatter.parse("ふつうのメッセージ")
        XCTAssertNil(parsed.quote)
        XCTAssertEqual(parsed.text, "ふつうのメッセージ")
    }

    func testPreviewTruncatesLongBody() {
        let long = String(repeating: "あ", count: 60)
        let preview = ChatReplyQuoteFormatter.preview(of: long)
        XCTAssertEqual(preview, String(repeating: "あ", count: 40) + "…")
    }
}
