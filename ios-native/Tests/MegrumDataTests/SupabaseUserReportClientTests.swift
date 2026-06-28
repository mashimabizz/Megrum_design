import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseUserReportClientTests: XCTestCase {
    func testBuildsCreateUserReportRequest() throws {
        let client = SupabaseUserReportClient(configuration: configuration)
        let reporterID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let input = UserReportCreateInput(
            targetUserID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            reason: .harassment,
            note: "不適切なやりとりです"
        )

        let request = try client.makeCreateReportRequest(reporterID: reporterID, input: input)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/reports?select=id,target_user_id,status,created_at")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["reporter_id"] as? String, reporterID.uuidString.lowercased())
        XCTAssertEqual(payload["target_user_id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(payload["category"] as? String, "harassment")
        XCTAssertEqual(payload["description"] as? String, "不適切なやりとりです")
        XCTAssertEqual(payload["evidence_urls"] as? [String], [])
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
