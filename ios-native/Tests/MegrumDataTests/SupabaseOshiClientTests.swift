import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseOshiClientTests: XCTestCase {
    func testBuildsGroupSearchRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)

        let request = try client.makeGroupsRequest(searchText: "TWICE", limit: 20)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/groups_master?select=id,name,aliases,display_order&order=display_order.asc,name.asc&limit=20&name=ilike.*TWICE*")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
    }

    func testBuildsCharactersRequestForGroup() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let groupID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!

        let request = try client.makeCharactersRequest(groupID: groupID, limit: 12)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/characters_master?select=id,group_id,name,aliases,display_order&group_id=eq.cccccccc-cccc-cccc-cccc-cccccccccccc&order=display_order.asc,name.asc&limit=12")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildsDeleteUserSelectionsRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeDeleteUserSelectionsRequest(userID: userID)

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_oshi?user_id=eq.11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
    }

    func testBuildsUpsertUserSelectionsRequest() throws {
        let client = SupabaseOshiClient(configuration: configuration)
        let selection = UserOshiSelection(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            groupID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            characterID: nil,
            kind: .box,
            priority: 1
        )

        let request = try client.makeUpsertUserSelectionsRequest([selection])
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/user_oshi?select=id,user_id,group_id,character_id,kind,priority")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "resolution=merge-duplicates,return=representation")
        XCTAssertEqual(json.first?["id"] as? String, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(json.first?["user_id"] as? String, "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(json.first?["group_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(json.first?["kind"] as? String, "box")
        XCTAssertEqual(json.first?["priority"] as? Int, 1)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
