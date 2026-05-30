import MegrumData
import XCTest

final class SupabaseConfigurationTests: XCTestCase {
    func testReadsExpoCompatibleEnvironmentKeys() {
        let config = SupabaseConfiguration.fromEnvironment([
            "EXPO_PUBLIC_SUPABASE_URL": "https://example.supabase.co",
            "EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test"
        ])

        XCTAssertEqual(config?.projectURL.absoluteString, "https://example.supabase.co")
        XCTAssertEqual(config?.publishableKey, "sb_publishable_test")
        XCTAssertNil(config?.accessToken)
    }

    func testBuildsPostgrestRequestHeaders() throws {
        let config = try XCTUnwrap(SupabaseConfiguration.fromEnvironment([
            "MEGRUM_SUPABASE_URL": "https://example.supabase.co",
            "MEGRUM_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
            "MEGRUM_SUPABASE_ACCESS_TOKEN": "session_token"
        ]))
        let client = SupabaseRESTClient(configuration: config)

        let request = try client.makeRequest(
            path: "/rest/v1/users",
            queryItems: [URLQueryItem(name: "select", value: "id,handle")]
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/users?select=id,handle")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }
}
