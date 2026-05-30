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

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
