import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseProposalClientTests: XCTestCase {
    func testBuildsLoadProposalsRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadProposalsRequest(viewerID: viewerID)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/proposals?select=id,sender_id,receiver_id,status,exchange_method,sender_have_ids,receiver_have_ids,option_tags,created_at"))
        XCTAssertTrue(url.contains("or=(sender_id.eq.11111111-1111-1111-1111-111111111111,receiver_id.eq.11111111-1111-1111-1111-111111111111)"))
        XCTAssertTrue(url.contains("order=created_at.desc"))
    }

    func testBuildsCreateProposalRequest() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let input = ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .mail,
            conditionTags: ["即日発送"],
            message: "よろしくお願いします"
        )

        let request = try client.makeCreateProposalRequest(senderID: senderID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["sender_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["receiver_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["match_type"] as? String, "forward")
        XCTAssertEqual(json.first?["sender_have_ids"] as? [String], ["33333333-3333-3333-3333-333333333333"])
        XCTAssertEqual(json.first?["sender_have_qtys"] as? [Int], [1])
        XCTAssertEqual(json.first?["receiver_have_ids"] as? [String], ["44444444-4444-4444-4444-444444444444"])
        XCTAssertEqual(json.first?["receiver_have_qtys"] as? [Int], [1])
        XCTAssertEqual(json.first?["status"] as? String, "sent")
        XCTAssertEqual(json.first?["exchange_method"] as? String, "mail")
        XCTAssertEqual(json.first?["option_tags"] as? [String], ["即日発送"])
        XCTAssertEqual(json.first?["message"] as? String, "よろしくお願いします")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
