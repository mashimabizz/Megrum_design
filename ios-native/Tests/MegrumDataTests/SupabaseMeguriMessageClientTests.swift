import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMeguriMessageClientTests: XCTestCase {
    func testBuildsMeguriMessagesRPCRequest() throws {
        let client = SupabaseMeguriMessageClient(configuration: configuration)

        let request = try client.makeLoadMessagesRequest()
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_meguri_messages_for_viewer")
        XCTAssertTrue(json.isEmpty)
    }

    func testBuildsMeguriMessageSendRequest() throws {
        let client = SupabaseMeguriMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let recipientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let groomReplyID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!

        let request = try client.makeSendTextMessageRequest(
            MeguriMessageCreateInput(
                senderID: senderID,
                recipientID: recipientID,
                sourceGroomReplyID: groomReplyID,
                body: " こんにちは "
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id,sender_id,recipient_id,source_groom_reply_id,message_type,body,image_url,image_path,read_at,created_at")
        XCTAssertEqual(payload["sender_id"] as? String, senderID.uuidString.lowercased())
        XCTAssertEqual(payload["recipient_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_reply_id"] as? String, groomReplyID.uuidString.lowercased())
        XCTAssertEqual(payload["message_type"] as? String, "text")
        XCTAssertEqual(payload["body"] as? String, "こんにちは")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
