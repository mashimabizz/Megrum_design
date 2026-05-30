import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMessageClientTests: XCTestCase {
    func testBuildsLoadMessagesRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let proposalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadMessagesRequest(proposalID: proposalID, limit: 50)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/messages?select=id,proposal_id,sender_id,message_type,body,photo_url,created_at"))
        XCTAssertTrue(url.contains("proposal_id=eq.11111111-1111-1111-1111-111111111111"))
        XCTAssertTrue(url.contains("order=created_at.asc"))
        XCTAssertTrue(url.contains("limit=50"))
    }

    func testBuildsSendTextMessageRequest() throws {
        let client = SupabaseMessageClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let proposalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeSendTextMessageRequest(
            senderID: senderID,
            input: TradeMessageCreateInput(proposalID: proposalID, body: " よろしくお願いします ")
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["proposal_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["message_type"] as? String, "text")
        XCTAssertEqual(json.first?["body"] as? String, "よろしくお願いします")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
