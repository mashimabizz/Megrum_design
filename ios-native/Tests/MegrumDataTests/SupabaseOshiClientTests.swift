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

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
