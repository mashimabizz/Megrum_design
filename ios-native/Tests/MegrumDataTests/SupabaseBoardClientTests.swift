import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseBoardClientTests: XCTestCase {
    func testBuildsBoardThreadRPCRequest() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
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

    func testNearbyBoardThreadRequestUsesLocationScopeOnly() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: " 東京都 ",
            scope: .nearby3km
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertTrue(json["p_prefecture"] is NSNull)
        XCTAssertEqual(json["p_scope"] as? String, "nearby_3km")
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
        XCTAssertTrue(loadJSON["p_prefecture"] is NSNull)
        XCTAssertEqual(loadJSON["p_scope"] as? String, "nearby_3km")

        let appendRequest = try client.makeAppendReplyRequest(
            BoardReplyCreateInput(
                threadID: threadID,
                body: " 了解です ",
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: "東京都",
                scope: .nearby3km
            )
        )
        let appendBody = try XCTUnwrap(appendRequest.httpBody)
        let appendJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: appendBody) as? [String: Any])

        XCTAssertEqual(appendRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/append_meguri_board_reply_for_viewer")
        XCTAssertEqual(appendJSON["p_body"] as? String, "了解です")
        XCTAssertEqual(appendJSON["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(appendJSON["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertTrue(appendJSON["p_prefecture"] is NSNull)
        XCTAssertEqual(appendJSON["p_scope"] as? String, "nearby_3km")
        XCTAssertTrue(appendJSON["p_parent_reply_id"] is NSNull)
        XCTAssertEqual((appendJSON["p_image_paths"] as? [String]) ?? ["unexpected"], [])
    }

    func testSamePrefectureBoardReplyRequestsUsePrefectureScopeOnly() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let loadRequest = try client.makeLoadRepliesRequest(
            threadID: threadID,
            latitude: 35.0,
            longitude: 139.0,
            prefecture: " 東京都 ",
            scope: .samePrefecture
        )
        let loadBody = try XCTUnwrap(loadRequest.httpBody)
        let loadJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: loadBody) as? [String: Any])

        XCTAssertTrue(loadJSON["p_viewer_lat"] is NSNull)
        XCTAssertTrue(loadJSON["p_viewer_lng"] is NSNull)
        XCTAssertEqual(loadJSON["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(loadJSON["p_scope"] as? String, "same_prefecture")

        let appendRequest = try client.makeAppendReplyRequest(
            BoardReplyCreateInput(
                threadID: threadID,
                body: " 都内なら行けます ",
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: " 東京都 ",
                scope: .samePrefecture
            )
        )
        let appendBody = try XCTUnwrap(appendRequest.httpBody)
        let appendJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: appendBody) as? [String: Any])

        XCTAssertEqual(appendJSON["p_body"] as? String, "都内なら行けます")
        XCTAssertTrue(appendJSON["p_viewer_lat"] is NSNull)
        XCTAssertTrue(appendJSON["p_viewer_lng"] is NSNull)
        XCTAssertEqual(appendJSON["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(appendJSON["p_scope"] as? String, "same_prefecture")
    }

    func testBuildsBoardThreadCreateRequest() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let authorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateThreadRequest(
            BoardThreadCreateInput(
                authorID: authorID,
                title: " 物販列どのくらい？ ",
                body: " 北口側が動いています ",
                audience: .nearby3km,
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: " 東京都 "
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let json = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(request.url?.absoluteString.hasPrefix("https://example.supabase.co/rest/v1/meguri_board_threads?select=id,author_id,title,body,audience_scope,origin_lat,origin_lng,prefecture,latest_activity_at,created_at") == true)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(json["author_id"] as? String, authorID.uuidString.uppercased())
        XCTAssertEqual(json["title"] as? String, "物販列どのくらい？")
        XCTAssertEqual(json["body"] as? String, "北口側が動いています")
        XCTAssertEqual(json["audience_scope"] as? String, "nearby_3km")
        XCTAssertEqual(json["category"] as? String, "chat")
        XCTAssertEqual((json["image_paths"] as? [String]) ?? ["unexpected"], [])
        XCTAssertEqual(json["origin_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["origin_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["prefecture"] as? String, "東京都")
        XCTAssertTrue(json["spot_key"] is NSNull)
        XCTAssertTrue(json["spot_label"] is NSNull)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
