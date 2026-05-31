import MegrumData
import XCTest

final class SupabaseConfigurationTests: XCTestCase {
    func testReadsInfoDictionaryKeys() {
        let config = SupabaseConfiguration.fromInfoDictionary([
            "MegrumSupabaseURL": "https://example.supabase.co",
            "MegrumSupabasePublishableKey": "sb_publishable_test"
        ])

        XCTAssertEqual(config?.projectURL.absoluteString, "https://example.supabase.co")
        XCTAssertEqual(config?.publishableKey, "sb_publishable_test")
        XCTAssertNil(config?.accessToken)
    }

    func testIgnoresUnresolvedBuildSettingPlaceholders() {
        let config = SupabaseConfiguration.fromInfoDictionary([
            "MegrumSupabaseURL": "$(MEGRUM_SUPABASE_URL)",
            "MegrumSupabasePublishableKey": "$(MEGRUM_SUPABASE_PUBLISHABLE_KEY)"
        ])

        XCTAssertNil(config)
    }

    func testRejectsRelativeSupabaseURL() {
        let config = SupabaseConfiguration.fromInfoDictionary([
            "MegrumSupabaseURL": "example.supabase.co",
            "MegrumSupabasePublishableKey": "sb_publishable_test"
        ])

        XCTAssertNil(config)
    }

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

    func testAccessTokenCanBeReplacedForAuthenticatedRequests() {
        let config = SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test",
            accessToken: nil
        )

        let authenticatedConfig = config.withAccessToken("session_token")

        XCTAssertEqual(authenticatedConfig.projectURL, config.projectURL)
        XCTAssertEqual(authenticatedConfig.publishableKey, config.publishableKey)
        XCTAssertEqual(authenticatedConfig.accessToken, "session_token")
    }

    func testBuildsStorageObjectUploadRequest() throws {
        let client = SupabaseRESTClient(configuration: configuration)
        let data = Data([0x01, 0x02, 0x03])

        let request = try client.makeStorageObjectUploadRequest(
            bucket: "groom-posts",
            path: "user-id/photo.jpg",
            data: data,
            contentType: "image/jpeg"
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/storage/v1/object/groom-posts/user-id/photo.jpg")
        XCTAssertEqual(request.httpBody, data)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
        XCTAssertEqual(request.value(forHTTPHeaderField: "cache-control"), "3600")
        XCTAssertNil(request.value(forHTTPHeaderField: "x-upsert"))
    }

    func testBuildsStorageSignedURLRequest() throws {
        let client = SupabaseRESTClient(configuration: configuration)

        let request = try client.makeStorageSignedURLRequest(
            bucket: "groom-posts",
            path: "user-id/photo.jpg",
            expiresIn: 7200
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/storage/v1/object/sign/groom-posts/user-id/photo.jpg")
        XCTAssertEqual(json["expiresIn"] as? Int, 7200)
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}
