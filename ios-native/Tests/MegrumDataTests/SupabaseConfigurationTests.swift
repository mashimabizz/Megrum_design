import Foundation
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

    func testBuildsFunctionRequest() throws {
        let configuration = SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test",
            accessToken: "session_token"
        )
        let client = SupabaseRESTClient(configuration: configuration)

        let request = try client.makeFunctionRequest(
            name: "suggest-goods-series",
            payload: FunctionRequestPayload(groupName: "BTS")
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/functions/v1/suggest-goods-series")
        XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "sb_publishable_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(json["group_name"] as? String, "BTS")
    }

    func testCreateSignedURLResolvesStorageRelativeObjectPath() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StorageSignedURLMockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        let client = SupabaseRESTClient(configuration: configuration, session: session)

        StorageSignedURLMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw StorageSignedURLMockError.missingURL
            }
            guard url.path == "/storage/v1/object/sign/chat-photos/proposal/photo.jpg" else {
                throw StorageSignedURLMockError.unexpectedRequest(url.absoluteString)
            }
            let data = Data(#"{"signedURL":"/object/sign/chat-photos/proposal/photo.jpg?token=abc"}"#.utf8)
            return (StorageSignedURLMockURLProtocol.response(for: url, statusCode: 200), data)
        }
        defer {
            StorageSignedURLMockURLProtocol.requestHandler = nil
        }

        let url = try await client.createSignedURL(
            bucket: "chat-photos",
            path: "proposal/photo.jpg"
        )

        XCTAssertEqual(
            url.absoluteString,
            "https://example.supabase.co/storage/v1/object/sign/chat-photos/proposal/photo.jpg?token=abc"
        )
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private enum StorageSignedURLMockError: Error {
    case missingURL
    case missingHandler
    case unexpectedRequest(String)
}

private struct FunctionRequestPayload: Encodable, Sendable {
    var groupName: String
}

private final class StorageSignedURLMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: StorageSignedURLMockError.missingHandler)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func response(for url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}
