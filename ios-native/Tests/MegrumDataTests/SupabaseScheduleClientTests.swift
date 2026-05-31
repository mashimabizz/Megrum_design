import Foundation
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

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
