import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseBoardClientTests: XCTestCase {
    func testBuildsBoardThreadRPCRequest() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: " 東京都 ",
            scope: .samePrefecture
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_meguri_board_threads_for_viewer")
        XCTAssertTrue(json["p_viewer_lat"] is NSNull)
        XCTAssertTrue(json["p_viewer_lng"] is NSNull)
        XCTAssertEqual(json["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(json["p_scope"] as? String, "same_prefecture")
    }

    func testNearbyBoardThreadRequestUsesLocationScopeOnly() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: " 東京都 ",
            scope: .nearby3km
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertTrue(json["p_prefecture"] is NSNull)
        XCTAssertEqual(json["p_scope"] as? String, "nearby_3km")
    }

    func testBuildsBoardReplyRPCRequests() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let loadRequest = try client.makeLoadRepliesRequest(
            threadID: threadID,
            latitude: 35.0,
            longitude: 139.0,
            prefecture: "東京都",
            scope: .nearby3km
        )
        let loadBody = try XCTUnwrap(loadRequest.httpBody)
        let loadJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: loadBody) as? [String: Any])

        XCTAssertEqual(loadRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/list_meguri_board_replies_for_viewer")
        XCTAssertEqual(loadJSON["p_thread_id"] as? String, threadID.uuidString.uppercased())
        XCTAssertEqual(loadJSON["p_viewer_lat"] as? Double, 35.0)
        XCTAssertEqual(loadJSON["p_viewer_lng"] as? Double, 139.0)
        XCTAssertTrue(loadJSON["p_prefecture"] is NSNull)
        XCTAssertEqual(loadJSON["p_scope"] as? String, "nearby_3km")

        let appendRequest = try client.makeAppendReplyRequest(
            BoardReplyCreateInput(
                threadID: threadID,
                body: " 了解です ",
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: "東京都",
                scope: .nearby3km
            )
        )
        let appendBody = try XCTUnwrap(appendRequest.httpBody)
        let appendJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: appendBody) as? [String: Any])

        XCTAssertEqual(appendRequest.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/append_meguri_board_reply_for_viewer")
        XCTAssertEqual(appendJSON["p_body"] as? String, "了解です")
        XCTAssertEqual(appendJSON["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(appendJSON["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertTrue(appendJSON["p_prefecture"] is NSNull)
        XCTAssertEqual(appendJSON["p_scope"] as? String, "nearby_3km")
        XCTAssertTrue(appendJSON["p_parent_reply_id"] is NSNull)
        XCTAssertEqual((appendJSON["p_image_paths"] as? [String]) ?? ["unexpected"], [])
    }

    func testSamePrefectureBoardReplyRequestsUsePrefectureScopeOnly() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let loadRequest = try client.makeLoadRepliesRequest(
            threadID: threadID,
            latitude: 35.0,
            longitude: 139.0,
            prefecture: " 東京都 ",
            scope: .samePrefecture
        )
        let loadBody = try XCTUnwrap(loadRequest.httpBody)
        let loadJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: loadBody) as? [String: Any])

        XCTAssertTrue(loadJSON["p_viewer_lat"] is NSNull)
        XCTAssertTrue(loadJSON["p_viewer_lng"] is NSNull)
        XCTAssertEqual(loadJSON["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(loadJSON["p_scope"] as? String, "same_prefecture")

        let appendRequest = try client.makeAppendReplyRequest(
            BoardReplyCreateInput(
                threadID: threadID,
                body: " 都内なら行けます ",
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: " 東京都 ",
                scope: .samePrefecture
            )
        )
        let appendBody = try XCTUnwrap(appendRequest.httpBody)
        let appendJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: appendBody) as? [String: Any])

        XCTAssertEqual(appendJSON["p_body"] as? String, "都内なら行けます")
        XCTAssertTrue(appendJSON["p_viewer_lat"] is NSNull)
        XCTAssertTrue(appendJSON["p_viewer_lng"] is NSNull)
        XCTAssertEqual(appendJSON["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(appendJSON["p_scope"] as? String, "same_prefecture")
    }

    func testSameSpotBoardReplyRequestsUseNearbyContext() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        let request = try client.makeLoadRepliesRequest(
            threadID: threadID,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: "東京都",
            scope: .sameSpot
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(json["p_scope"] as? String, "nearby_3km")
    }

    func testGlobalBoardThreadRequestKeepsGlobalScopeContext() throws {
        let client = SupabaseBoardClient(configuration: configuration)

        let request = try client.makeLoadThreadsRequest(
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: " 東京都 ",
            scope: .global
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_viewer_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_viewer_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["p_prefecture"] as? String, "東京都")
        XCTAssertEqual(json["p_scope"] as? String, "global")
    }

    func testLoadThreadsFiltersUnexpectedFarNearbyRowsClientSide() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BoardMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseBoardClient(configuration: self.configuration, session: session)

        BoardMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw BoardMockError.missingURL
            }
            XCTAssertEqual(url.path, "/rest/v1/rpc/list_meguri_board_threads_for_viewer")
            let data = Data("""
            [
              {
                "id": "00000000-0000-0000-0000-000000000601",
                "author_id": "00000000-0000-0000-0000-000000000001",
                "title": "近いスレッド",
                "body": "近くです",
                "audience_scope": "nearby_3km",
                "origin_lat": 35.681236,
                "origin_lng": 139.767125,
                "prefecture": "東京都",
                "anonymous_display_name": "まくはり民",
                "anonymous_avatar_id": "avatar_3",
                "latest_activity_at": "2026-05-31T00:00:00Z",
                "created_at": "2026-05-31T00:00:00Z"
              },
              {
                "id": "00000000-0000-0000-0000-000000000602",
                "author_id": "00000000-0000-0000-0000-000000000002",
                "title": "遠いスレッド",
                "body": "遠くです",
                "audience_scope": "nearby_3km",
                "origin_lat": 35.751236,
                "origin_lng": 139.767125,
                "prefecture": "東京都",
                "latest_activity_at": "2026-05-31T00:00:00Z",
                "created_at": "2026-05-31T00:00:00Z"
              }
            ]
            """.utf8)
            return (BoardMockURLProtocol.response(for: url, statusCode: 200), data)
        }
        defer {
            BoardMockURLProtocol.requestHandler = nil
        }

        let threads = try waitForBoardAsyncResult {
            try await client.loadThreads(
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: "東京都",
                scope: .nearby3km
            )
        }

        XCTAssertEqual(threads.map(\.title), ["近いスレッド"])
        XCTAssertEqual(threads.first?.anonymousDisplayName, "まくはり民")
        XCTAssertEqual(threads.first?.anonymousAvatarID, "avatar_3")
    }

    func testBuildsBoardThreadCreateRequest() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let authorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateThreadRequest(
            BoardThreadCreateInput(
                authorID: authorID,
                title: " 物販列どのくらい？ ",
                body: " 北口側が動いています ",
                audience: .nearby3km,
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: " 東京都 ",
                imagePaths: ["board_threads/22222222-2222-2222-2222-222222222222/thumb.jpg"]
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/create_meguri_board_thread_for_viewer")
        XCTAssertNil(request.value(forHTTPHeaderField: "Prefer"))
        XCTAssertEqual(json["p_title"] as? String, "物販列どのくらい？")
        XCTAssertEqual(json["p_body"] as? String, "北口側が動いています")
        XCTAssertEqual(json["p_scope"] as? String, "nearby_3km")
        XCTAssertEqual((json["p_image_paths"] as? [String]) ?? ["unexpected"], ["board_threads/22222222-2222-2222-2222-222222222222/thumb.jpg"])
        XCTAssertTrue(json["p_anonymous_display_name"] is NSNull)
        XCTAssertTrue(json["p_anonymous_avatar_id"] is NSNull)
        XCTAssertEqual(json["p_origin_lat"] as? Double, 35.681236)
        XCTAssertEqual(json["p_origin_lng"] as? Double, 139.767125)
        XCTAssertEqual(json["p_prefecture"] as? String, "東京都")
    }

    func testBuildsBoardThreadCreateRequestWithAnonymousProfile() throws {
        let client = SupabaseBoardClient(configuration: configuration)
        let authorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let request = try client.makeCreateThreadRequest(
            BoardThreadCreateInput(
                authorID: authorID,
                title: "現地の様子",
                body: "入場列の情報です",
                audience: .nearby3km,
                latitude: 35.681236,
                longitude: 139.767125,
                prefecture: "東京都",
                anonymousDisplayName: " まくはり民 ",
                anonymousAvatarID: " avatar_3 "
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(json["p_anonymous_display_name"] as? String, "まくはり民")
        XCTAssertEqual(json["p_anonymous_avatar_id"] as? String, "avatar_3")
    }

    func testAppendReplyThrowsMalformedResponseWhenRPCReturnsNoRows() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BoardMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseBoardClient(configuration: self.configuration, session: session)
        let threadID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        BoardMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw BoardMockError.missingURL
            }
            XCTAssertEqual(url.path, "/rest/v1/rpc/append_meguri_board_reply_for_viewer")
            return (BoardMockURLProtocol.response(for: url, statusCode: 200), Data("[]".utf8))
        }
        defer {
            BoardMockURLProtocol.requestHandler = nil
        }

        do {
            _ = try waitForBoardAsyncResult {
                try await client.appendReply(
                    BoardReplyCreateInput(
                        threadID: threadID,
                        body: "空レスポンス",
                        latitude: 35.681236,
                        longitude: 139.767125,
                        prefecture: "東京都",
                        scope: .nearby3km
                    )
                )
            }
            XCTFail("Expected malformed response")
        } catch let error as SupabaseBoardClientError {
            XCTAssertEqual(error, .malformedResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateThreadThrowsMalformedResponseWhenRPCReturnsNoRows() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BoardMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseBoardClient(configuration: self.configuration, session: session)
        let authorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        BoardMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw BoardMockError.missingURL
            }
            XCTAssertEqual(url.path, "/rest/v1/rpc/create_meguri_board_thread_for_viewer")
            return (BoardMockURLProtocol.response(for: url, statusCode: 200), Data("[]".utf8))
        }
        defer {
            BoardMockURLProtocol.requestHandler = nil
        }

        do {
            _ = try waitForBoardAsyncResult {
                try await client.createThread(
                    BoardThreadCreateInput(
                        authorID: authorID,
                        title: "空レスポンス",
                        body: "作成できたように見せない",
                        audience: .nearby3km,
                        latitude: 35.681236,
                        longitude: 139.767125,
                        prefecture: "東京都"
                    )
                )
            }
            XCTFail("Expected malformed response")
        } catch let error as SupabaseBoardClientError {
            XCTAssertEqual(error, .malformedResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }
}

private func waitForBoardAsyncResult<Value: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Value,
    timeout: TimeInterval = 3
) throws -> Value {
    let semaphore = DispatchSemaphore(value: 0)
    let resultBox = BoardAsyncResultBox<Value>()

    Task {
        do {
            resultBox.store(.success(try await operation()))
        } catch {
            resultBox.store(.failure(error))
        }
        semaphore.signal()
    }

    XCTAssertEqual(semaphore.wait(timeout: .now() + timeout), .success)
    return try XCTUnwrap(resultBox.result).get()
}

private final class BoardAsyncResultBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedResult: Result<Value, Error>?

    var result: Result<Value, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return storedResult
    }

    func store(_ result: Result<Value, Error>) {
        lock.lock()
        storedResult = result
        lock.unlock()
    }
}

private enum BoardMockError: Error {
    case missingHandler
    case missingURL
}

private final class BoardMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: BoardMockError.missingHandler)
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
