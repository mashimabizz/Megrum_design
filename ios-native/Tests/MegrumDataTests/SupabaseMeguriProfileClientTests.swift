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
            "https://example.supabase.co/rest/v1/meguri_profiles?select=user_id,display_name,avatar_id,avatar_url,uses_public_profile,last_changed_at,created_at,updated_at&user_id=in.(00000000-0000-0000-0000-000000000001)"
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
        XCTAssertNil(json["p_avatar_url"])
        XCTAssertEqual(json["p_uses_public_profile"] as? Bool, false)
    }

    func testBuildsSaveProfileRPCRequestWithCustomAvatarURL() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)

        let request = try client.makeSaveProfileRequest(
            MeguriProfileUpdateInput(
                displayName: "めぐり名",
                avatarID: "avatar_3",
                avatarURL: URL(string: "https://example.com/avatar.jpg")
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_avatar_url"] as? String, "https://example.com/avatar.jpg")
    }

    func testBuildsSaveProfileRPCRequestUsingPublicProfileIdentity() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)

        let request = try client.makeSaveProfileRequest(
            MeguriProfileUpdateInput(
                displayName: "めぐり名",
                avatarID: "avatar_3",
                usesPublicProfile: true
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_uses_public_profile"] as? Bool, true)
    }

    func testBuildsSaveProfileRPCRequestClearingCustomAvatarURL() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)

        let request = try client.makeSaveProfileRequest(
            MeguriProfileUpdateInput(
                displayName: "めぐり名",
                avatarID: "avatar_3",
                clearsAvatarURL: true
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertTrue(json.keys.contains("p_avatar_url"))
        XCTAssertTrue(json["p_avatar_url"] is NSNull)
    }

    func testBuildsUpsertProfileFallbackRequest() throws {
        let client = SupabaseMeguriProfileClient(configuration: configuration)
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let request = try client.makeUpsertProfileRequest(
            MeguriProfileUpdateInput(displayName: " めぐり名 ", avatarID: " avatar_3 "),
            userID: userID
        )
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://example.supabase.co/rest/v1/meguri_profiles?select=user_id,display_name,avatar_id,avatar_url,uses_public_profile,last_changed_at,created_at,updated_at&on_conflict=user_id"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(payload["user_id"] as? String, userID.uuidString.lowercased())
        XCTAssertEqual(payload["display_name"] as? String, "めぐり名")
        XCTAssertEqual(payload["avatar_id"] as? String, "avatar_3")
        XCTAssertEqual(payload["uses_public_profile"] as? Bool, false)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
