import Foundation
import MegrumCore
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

    func testBuildsGroomPostCreateRequest() throws {
        let client = SupabaseGroomClient(configuration: configuration)
        let authorID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let request = try client.makeCreatePostRequest(
            GroomPostCreateInput(
                authorID: authorID,
                imageData: Data([0xff, 0xd8, 0xff]),
                imageContentType: "image/jpeg",
                caption: " 物販列メモ ",
                latitude: 35.681236,
                longitude: 139.767125
            ),
            imagePath: "00000000-0000-0000-0000-000000000001/test.jpg"
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_posts?select=id,user_id,image_url,image_path,published_at,created_at,origin_lat,origin_lng")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=representation")
        XCTAssertEqual(payload["user_id"] as? String, authorID.uuidString.lowercased())
        XCTAssertEqual(payload["status"] as? String, "published")
        XCTAssertEqual(payload["audience_scope"] as? String, "encountered_people")
        XCTAssertEqual(payload["image_path"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["image_url"] as? String, "00000000-0000-0000-0000-000000000001/test.jpg")
        XCTAssertEqual(payload["caption"] as? String, "物販列メモ")
        XCTAssertEqual(payload["origin_lat"] as? Double, 35.681236)
        XCTAssertEqual(payload["origin_lng"] as? Double, 139.767125)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
