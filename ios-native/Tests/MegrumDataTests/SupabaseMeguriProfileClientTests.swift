import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMeguriProfileClientTests: XCTestCase {
    func testBuildsLoadProfilesRequest() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let request = try client.makeLoadProfilesRequest(userIDs: [userID])

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/meguri_profiles?select=user_id,display_name,avatar_id,last_changed_at,created_at,updated_at&user_id=in.(00000000-0000-0000-0000-000000000001)"
        )
    }

    func testBuildsSaveProfileRPCRequest() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)

        let request = try client.makeSaveProfileRequest(
            MeguriProfileUpdateInput(displayName: " めぐり名 ", avatarID: " avatar_3 ")
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/set_meguri_profile_for_viewer")
        XCTAssertEqual(json["p_display_name"] as? String, "めぐり名")
        XCTAssertEqual(json["p_avatar_id"] as? String, "avatar_3")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
