import Foundation
import MegrumData
import XCTest

final class SupabaseBlockClientTests: XCTestCase {
    func testBuildsBlockUserRequest() throws {
        let client = SupabaseBlockClient(configuration: configuration)
        let blockerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let blockedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeBlockUserRequest(blockerID: blockerID, blockedID: blockedID)
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        let payload = try XCTUnwrap(rows.first)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_user_blocks?select=blocked_id,created_at&on_conflict=blocker_id,blocked_id")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(payload["blocker_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(payload["blocked_id"] as? String, "22222222-2222-2222-2222-222222222222")
    }

    func testBuildsLoadBlocksRequest() throws {
        let client = SupabaseBlockClient(configuration: configuration)
        let blockerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadBlocksRequest(blockerID: blockerID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_user_blocks?select=blocked_id,created_at&blocker_id=eq.11111111-1111-1111-1111-111111111111&order=created_at.desc")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsLoadBlockedUserIDsRequest() throws {
        let client = SupabaseBlockClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadBlockedUserIDsRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_user_blocks?select=blocker_id,blocked_id&or=(blocker_id.eq.11111111-1111-1111-1111-111111111111,blocked_id.eq.11111111-1111-1111-1111-111111111111)")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsLoadBlockedProfilesRequest() throws {
        let client = SupabaseBlockClient(configuration: configuration)
        let userIDs = [
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        ]

        let request = try client.makeLoadBlockedProfilesRequest(userIDs: userIDs)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/users?select=id,handle,display_name,avatar_url&id=in.(22222222-2222-2222-2222-222222222222,33333333-3333-3333-3333-333333333333)")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsUnblockRequest() throws {
        let client = SupabaseBlockClient(configuration: configuration)
        let blockerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let blockedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeUnblockRequest(blockerID: blockerID, blockedID: blockedID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groom_user_blocks?blocker_id=eq.11111111-1111-1111-1111-111111111111&blocked_id=eq.22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
