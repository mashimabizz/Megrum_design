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
        let groomPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        let request = try client.makeSendTextMessageRequest(
            MeguriMessageCreateInput(
                senderID: senderID,
                recipientID: recipientID,
                sourceGroomReplyID: groomReplyID,
                sourceGroomPostID: groomPostID,
                sourceGroomOwnerID: recipientID,
                sourceGroomImageURL: URL(string: "https://example.com/groom.jpg"),
                body: " こんにちは "
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id,sender_id,recipient_id,source_groom_reply_id,source_groom_post_id,source_groom_owner_id,source_groom_image_url,message_type,body,image_url,image_path,read_at,created_at")
        XCTAssertEqual(payload["sender_id"] as? String, senderID.uuidString.lowercased())
        XCTAssertEqual(payload["recipient_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_reply_id"] as? String, groomReplyID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_post_id"] as? String, groomPostID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_owner_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_image_url"] as? String, "https://example.com/groom.jpg")
        XCTAssertEqual(payload["message_type"] as? String, "text")
        XCTAssertEqual(payload["body"] as? String, "こんにちは")
    }

    func testBuildsMeguriImageMessageSendRequest() throws {
        let client = SupabaseMeguriMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let recipientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let groomReplyID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!
        let groomPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        let request = try client.makeSendImageMessageRequest(
            senderID: senderID,
            recipientID: recipientID,
            sourceGroomReplyID: groomReplyID,
            sourceGroomPostID: groomPostID,
            sourceGroomOwnerID: recipientID,
            sourceGroomImageURL: URL(string: "https://example.com/groom.jpg"),
            imagePath: "00000000-0000-0000-0000-000000000001/message-1700000000000-photo.jpg",
            body: " 写真です "
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id,sender_id,recipient_id,source_groom_reply_id,source_groom_post_id,source_groom_owner_id,source_groom_image_url,message_type,body,image_url,image_path,read_at,created_at")
        XCTAssertEqual(payload["sender_id"] as? String, senderID.uuidString.lowercased())
        XCTAssertEqual(payload["recipient_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_reply_id"] as? String, groomReplyID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_post_id"] as? String, groomPostID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_owner_id"] as? String, recipientID.uuidString.lowercased())
        XCTAssertEqual(payload["source_groom_image_url"] as? String, "https://example.com/groom.jpg")
        XCTAssertEqual(payload["message_type"] as? String, "image")
        XCTAssertEqual(payload["body"] as? String, "写真です")
        XCTAssertEqual(payload["image_path"] as? String, "00000000-0000-0000-0000-000000000001/message-1700000000000-photo.jpg")
    }

    func testBuildsMeguriMessageMarkReadRequest() throws {
        let client = SupabaseMeguriMessageClient(configuration: configuration)
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let readAt = Date(timeIntervalSince1970: 1_800_000_000)

        let request = try client.makeMarkConversationReadRequest(
            viewerID: viewerID,
            peerID: peerID,
            sourceGroomPostID: nil,
            readAt: readAt
        )
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id,sender_id,recipient_id,source_groom_reply_id,source_groom_post_id,source_groom_owner_id,source_groom_image_url,message_type,body,image_url,image_path,read_at,created_at&recipient_id=eq.00000000-0000-0000-0000-000000000001&sender_id=eq.00000000-0000-0000-0000-000000000002&read_at=is.null&source_groom_post_id=is.null")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["read_at"] as? String, "2027-01-15T08:00:00.000Z")
    }

    func testBuildsMeguriMessageMarkReadRequestForSpecificGroomConversation() throws {
        let client = SupabaseMeguriMessageClient(configuration: configuration)
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let sourceGroomPostID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let readAt = Date(timeIntervalSince1970: 1_800_000_000)

        let request = try client.makeMarkConversationReadRequest(
            viewerID: viewerID,
            peerID: peerID,
            sourceGroomPostID: sourceGroomPostID,
            readAt: readAt
        )

        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/meguri_messages?select=id,sender_id,recipient_id,source_groom_reply_id,source_groom_post_id,source_groom_owner_id,source_groom_image_url,message_type,body,image_url,image_path,read_at,created_at&recipient_id=eq.00000000-0000-0000-0000-000000000001&sender_id=eq.00000000-0000-0000-0000-000000000002&read_at=is.null&source_groom_post_id=eq.00000000-0000-0000-0000-000000000501")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
