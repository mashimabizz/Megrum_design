import Foundation
import MegrumData
import XCTest

final class SupabaseUserProfileClientTests: XCTestCase {
    func testBuildsPublicProfileRPCRequest() throws {
        let client = SupabaseUserProfileClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadProfileRequest(userID: userID)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/get_public_user_profile_for_viewer")
        XCTAssertEqual(json["p_user_id"] as? String, userID.uuidString.uppercased())
    }

    func testBuildsEvaluationListRPCRequestWithClampedLimit() throws {
        let client = SupabaseUserProfileClient(configuration: configuration)
        let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeLoadEvaluationsRequest(userID: userID, limit: 500)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_user_evaluations_for_profile")
        XCTAssertEqual(json["p_user_id"] as? String, userID.uuidString.uppercased())
        XCTAssertEqual(json["p_limit"] as? Int, 100)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
