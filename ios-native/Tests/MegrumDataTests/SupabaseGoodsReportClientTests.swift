import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGoodsReportClientTests: XCTestCase {
    func testBuildsCreateGoodsReportRequest() throws {
        let client = SupabaseGoodsReportClient(configuration: configuration)
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = GoodsReportCreateInput(
            goodsItemID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            reportedUserID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            reason: .fakeItem,
            note: "説明と違います"
        )

        let request = try client.makeCreateReportRequest(reporterID: reporterID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/goods_reports?select=id,goods_inventory_id,status,created_at")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["reporter_id"] as? String, reporterID.uuidString.lowercased())
        XCTAssertEqual(payload["goods_inventory_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(payload["reported_user_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(payload["reason"] as? String, "fake_item")
        XCTAssertEqual(payload["note"] as? String, "説明と違います")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
