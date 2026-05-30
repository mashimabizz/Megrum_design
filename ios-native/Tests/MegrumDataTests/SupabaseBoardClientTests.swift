import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseBoardClientTests: XCTestCase {
    func testBuildsBoardThreadRPCRequest() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: nil,
            longitude: nil,
            prefecture: " 東京都 ",
            scope: .samePrefecture
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_meguri_board_threads_for_viewer")
        XCTAssertTrue(json["p_viewer_lat"] is NSNull)
        XCTAssertTrue(json["p_viewer_lng"] is NSNull)
        XCTAssertEqual(json["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(json["p_scope"] as? String, "same_prefecture")
    }

    func testBuildsBoardReplyRPCRequests() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let loadRequest = try client.makeLoadRepliesRequest(
            threadID: threadID,
            latitude: 35.0,
            longitude: 139.0,
            prefecture: "東京都",
            scope: .nearby3km
        )
        let loadBody = try XCTUnwrap(loadRequest.httpBody)
        let loadJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: loadBody) as? [String: Any])

        XCTAssertEqual(loadRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_meguri_board_replies_for_viewer")
        XCTAssertEqual(loadJSON["p_thread_id"] as? String, threadID.uuidString.uppercased())
        XCTAssertEqual(loadJSON["p_viewer_lat"] as? Double, 35.0)
        XCTAssertEqual(loadJSON["p_viewer_lng"] as? Double, 139.0)
        XCTAssertEqual(loadJSON["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(loadJSON["p_scope"] as? String, "nearby_3km")

        let appendRequest = try client.makeAppendReplyRequest(
            BoardReplyCreateInput(
                threadID: threadID,
                body: " 了解です ",
                prefecture: "東京都",
                scope: .nearby3km
            )
        )
        let appendBody = try XCTUnwrap(appendRequest.httpBody)
        let appendJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: appendBody) as? [String: Any])

        XCTAssertEqual(appendRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/append_meguri_board_reply_for_viewer")
        XCTAssertEqual(appendJSON["p_body"] as? String, "了解です")
        XCTAssertTrue(appendJSON["p_parent_reply_id"] is NSNull)
        XCTAssertEqual((appendJSON["p_image_paths"] as? [String]) ?? ["unexpected"], [])
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
