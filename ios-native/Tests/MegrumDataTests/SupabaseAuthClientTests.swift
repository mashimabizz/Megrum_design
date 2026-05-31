import MegrumData
import XCTest

final class SupabaseAuthClientTests: XCTestCase {
    func testBuildsPasswordSignInRequest() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makePasswordSignInRequest(
            email: " michi@example.com ",
            password: "password123"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/token?grant_type=password")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["email"] as? String, "michi@example.com")
        XCTAssertEqual(body["password"] as? String, "password123")
    }

    func testBuildsSignUpRequestWithMetadataAndRedirect() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeSignUpRequest(
            email: "michi@example.com",
            password: "password123",
            metadata: SupabaseAuthProfileMetadata(handle: "michi1", displayName: "みちりおん"),
            emailRedirectTo: URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/signup")
        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["email"] as? String, "michi@example.com")
        XCTAssertEqual(body["password"] as? String, "password123")
        XCTAssertEqual(body["email_redirect_to"] as? String, "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")

        let data = try XCTUnwrap(body["data"] as? [String: Any])
        XCTAssertEqual(data["handle"] as? String, "michi1")
        XCTAssertEqual(data["display_name"] as? String, "みちりおん")
    }

    func testBuildsIDTokenSignInRequestForApple() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeIDTokenSignInRequest(
            provider: .apple,
            idToken: "apple_id_token",
            nonce: "raw_nonce"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/token?grant_type=id_token")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sb_publishable_test")

        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["provider"] as? String, "apple")
        XCTAssertEqual(body["id_token"] as? String, "apple_id_token")
        XCTAssertEqual(body["nonce"] as? String, "raw_nonce")
        XCTAssertNil(body["access_token"])
    }

    func testBuildsPasswordResetRequestWithRedirect() throws {
        let client = SupabaseAuthClient(configuration: configuration)
        let redirectURL = URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")!

        let request = try client.makePasswordResetRequest(
            email: "michi@example.com",
            emailRedirectTo: redirectURL
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sb_publishable_test")

        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.supabase.co")
        XCTAssertEqual(components.path, "/auth/v1/recover")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "redirect_to" })?.value, redirectURL.absoluteString)

        let body = try XCTUnwrap(request.jsonBody)
        XCTAssertEqual(body["email"] as? String, "michi@example.com")
    }

    func testBuildsGoogleOAuthAuthorizeRequest() throws {
        let client = SupabaseAuthClient(configuration: configuration)
        let redirectURL = URL(string: "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview")!

        let request = try client.makeOAuthAuthorizeRequest(
            provider: .google,
            redirectTo: redirectURL,
            scopes: [" email ", "profile", ""]
        )

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "text/html,application/xhtml+xml,application/json")

        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.supabase.co")
        XCTAssertEqual(components.path, "/auth/v1/authorize")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "provider" })?.value, "google")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "redirect_to" })?.value, redirectURL.absoluteString)
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "scopes" })?.value, "email profile")
    }

    func testBuildsSignOutRequestWithSessionBearer() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeSignOutRequest(accessToken: "session_token")

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/logout")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
    }

    func testBuildsUserRequestWithRedirectBearer() throws {
        let client = SupabaseAuthClient(configuration: configuration)

        let request = try client.makeUserRequest(accessToken: "redirect_access_token")

        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/auth/v1/user")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer redirect_access_token")
    }

    func testParsesRedirectFragmentTokens() throws {
        let url = try XCTUnwrap(URL(string: "megrum-preview://auth/callback#access_token=redirect_access_token&refresh_token=refresh_token&expires_in=3600&token_type=bearer"))

        let payload = SupabaseAuthRedirectParser.parse(url)

        XCTAssertEqual(payload?.accessToken, "redirect_access_token")
        XCTAssertEqual(payload?.refreshToken, "refresh_token")
        XCTAssertEqual(payload?.expiresIn, 3600)
        XCTAssertEqual(payload?.tokenType, "bearer")
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private extension URLRequest {
    var jsonBody: [String: Any]? {
        guard let httpBody else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: httpBody) as? [String: Any]
    }
}
