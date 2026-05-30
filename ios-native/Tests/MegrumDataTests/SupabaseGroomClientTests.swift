import Foundation
import MegrumData
import XCTest

final class SupabaseGroomClientTests: XCTestCase {
    func testBuildsNearbyGroomRPCRequest() throws {
        let client = SupabaseGroomClient(configuration: configuration)

        let request = try client.makeLoadNearbyGroomsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            radiusMeters: 2_500
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_groom_feed_nearby")
        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["p_radius_m"] as? Int, 1_000)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
