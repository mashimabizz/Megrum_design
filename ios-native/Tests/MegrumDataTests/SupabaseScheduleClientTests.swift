import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseScheduleClientTests: XCTestCase {
    func testBuildsLoadSchedulesRequest() throws {
        let client = SupabaseScheduleClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let partnerID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let startAt = Date(timeIntervalSince1970: 1_780_160_000)
        let endAt = Date(timeIntervalSince1970: 1_780_246_400)

        let request = try client.makeLoadSchedulesRequest(
            userIDs: [viewerID, partnerID],
            startAt: startAt,
            endAt: endAt,
            limit: 80
        )
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/schedules?select=id,user_id,title,place_name,start_at,end_at,all_day,note"))
        XCTAssertTrue(url.contains("user_id=in.(11111111-1111-1111-1111-111111111111,22222222-2222-2222-2222-222222222222)"))
        XCTAssertTrue(url.contains("start_at=lt."))
        XCTAssertTrue(url.contains("end_at=gt."))
        XCTAssertTrue(url.contains("order=start_at.asc"))
        XCTAssertTrue(url.contains("limit=80"))
    }

    func testBuildsCreateScheduleRequest() throws {
        let client = SupabaseScheduleClient(configuration: configuration)
        let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let formatter = ISO8601DateFormatter()
        let startAt = formatter.date(from: "2026-05-29T12:26:40Z")!
        let endAt = formatter.date(from: "2026-05-29T13:26:40Z")!
        let input = PersonalScheduleCreateInput(
            title: " 物販列 ",
            placeName: " 北口 ",
            startAt: startAt,
            endAt: endAt,
            note: " 友達と合流 "
        )

        let request = try client.makeCreateScheduleRequest(userID: viewerID, input: input)
        let url = try XCTUnwrap(request.url?.absoluteString.removingPercentEncoding)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(url.hasPrefix("https://example.supabase.co/rest/v1/schedules?select=id,user_id,title,place_name,start_at,end_at,all_day,note"))
        XCTAssertEqual(payload["user_id"] as? String, viewerID.uuidString.lowercased())
        XCTAssertEqual(payload["title"] as? String, "物販列")
        XCTAssertEqual(payload["place_name"] as? String, "北口")
        XCTAssertEqual(payload["start_at"] as? String, "2026-05-29T12:26:40Z")
        XCTAssertEqual(payload["end_at"] as? String, "2026-05-29T13:26:40Z")
        XCTAssertEqual(payload["all_day"] as? Bool, false)
        XCTAssertEqual(payload["note"] as? String, "友達と合流")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
