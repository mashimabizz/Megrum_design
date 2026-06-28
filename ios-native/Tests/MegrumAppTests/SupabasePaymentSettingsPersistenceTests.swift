@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabasePaymentSettingsPersistenceTests: XCTestCase {
    func testReturnedSettingsPreservesNormalizedMethodsFromSummaryUpdate() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let stored = UserPaymentSettings(
            userID: userID,
            methods: [],
            bankName: "みずほ銀行",
            bankBranchName: "渋谷支店",
            bankAccountType: "普通",
            bankAccountNumber: "1234567",
            bankAccountHolder: "ヤマダ ハナコ",
            otherNote: "メルペイ相談可",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let normalized = UserPaymentSettings(
            userID: userID,
            methods: [.paypay, .bankTransfer],
            otherNote: "メルペイ相談可"
        )

        let returned = SupabasePaymentSettingsPersistence.returnedSettings(
            storedSettings: stored,
            normalizedSettings: normalized
        )

        XCTAssertEqual(returned.userID, userID)
        XCTAssertEqual(returned.methods, [.bankTransfer, .paypay])
        XCTAssertEqual(returned.bankName, "みずほ銀行")
        XCTAssertEqual(returned.bankBranchName, "渋谷支店")
        XCTAssertEqual(returned.bankAccountType, "普通")
        XCTAssertEqual(returned.bankAccountNumber, "1234567")
        XCTAssertEqual(returned.bankAccountHolder, "ヤマダ ハナコ")
        XCTAssertEqual(returned.otherNote, "メルペイ相談可")
        XCTAssertEqual(returned.createdAt, createdAt)
        XCTAssertEqual(returned.updatedAt, updatedAt)
    }

    func testFallbackProfileReflectsNormalizedPaymentSummary() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000702")!
        let normalized = UserPaymentSettings(
            userID: userID,
            methods: [.other, .cashExchange],
            otherNote: "楽天ペイも相談可"
        )

        let profile = SupabasePaymentSettingsPersistence.fallbackProfile(
            userID: userID,
            normalizedSettings: normalized
        )

        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "unknown")
        XCTAssertEqual(profile.displayName, "Megrum")
        XCTAssertEqual(profile.paymentMethods, [.cashExchange, .other])
        XCTAssertEqual(profile.paymentNote, "楽天ペイも相談可")
        XCTAssertEqual(profile.accountStatus, .active)
    }

    func testSaveSettingsFailsWhenDetailUpsertFails() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000703")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PaymentSettingsMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseRESTClient(
            configuration: SupabaseConfiguration(
                projectURL: URL(string: "https://example.supabase.co")!,
                publishableKey: "anon-key",
                accessToken: "user-token"
            ),
            session: session
        )
        let persistence = SupabasePaymentSettingsPersistence(client: client)
        var requestPaths: [String] = []

        PaymentSettingsMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw PaymentSettingsMockError.missingURL
            }
            requestPaths.append(url.path)

            if request.httpMethod == "POST", url.path == "/rest/v1/user_payment_settings" {
                return (
                    PaymentSettingsMockURLProtocol.response(for: url, statusCode: 500),
                    Data(#"{"message":"temporary settings table failure"}"#.utf8)
                )
            }

            throw PaymentSettingsMockError.unexpectedRequest(url.path)
        }
        defer {
            PaymentSettingsMockURLProtocol.requestHandler = nil
        }

        do {
            _ = try await persistence.saveSettings(
                UserPaymentSettings(
                    userID: userID,
                    methods: [.other, .bankTransfer],
                    bankName: "みずほ銀行",
                    bankBranchName: "渋谷支店",
                    bankAccountType: "普通",
                    bankAccountNumber: "1234567",
                    bankAccountHolder: "ヤマダ ハナコ",
                    otherNote: "メルペイ"
                ),
                userID: userID
            )
            XCTFail("詳細の支払い設定保存に失敗した場合は成功扱いにしない")
        } catch {}

        XCTAssertEqual(requestPaths, ["/rest/v1/user_payment_settings"])
    }

    func testLoadSettingsRestoresMethodsFromDetailRow() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000705")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PaymentSettingsMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseRESTClient(
            configuration: SupabaseConfiguration(
                projectURL: URL(string: "https://example.supabase.co")!,
                publishableKey: "anon-key",
                accessToken: "user-token"
            ),
            session: session
        )
        let persistence = SupabasePaymentSettingsPersistence(client: client)
        var requestQueries: [String] = []

        PaymentSettingsMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw PaymentSettingsMockError.missingURL
            }
            requestQueries.append(url.query ?? "")

            if request.httpMethod == "GET", url.path == "/rest/v1/user_payment_settings" {
                XCTAssertTrue((url.query ?? "").contains("payment_methods"))
                let data = Data("""
                [
                  {
                    "user_id": "\(userID.uuidString.lowercased())",
                    "payment_methods": ["bank_transfer", "cash_exchange"],
                    "bank_name": "三井住友銀行",
                    "bank_branch_name": "新宿支店",
                    "bank_account_type": "普通",
                    "bank_account_number": "7654321",
                    "bank_account_holder": "メグルム タロウ",
                    "other_note": null,
                    "created_at": null,
                    "updated_at": null
                  }
                ]
                """.utf8)
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            throw PaymentSettingsMockError.unexpectedRequest(url.path)
        }
        defer {
            PaymentSettingsMockURLProtocol.requestHandler = nil
        }

        let loaded = try await persistence.loadSettings(userID: userID)

        XCTAssertEqual(requestQueries.count, 1)
        XCTAssertEqual(loaded?.methods, [.bankTransfer, .cashExchange])
        XCTAssertEqual(loaded?.bankName, "三井住友銀行")
        XCTAssertEqual(loaded?.bankBranchName, "新宿支店")
        XCTAssertEqual(loaded?.bankAccountType, "普通")
        XCTAssertEqual(loaded?.bankAccountNumber, "7654321")
        XCTAssertEqual(loaded?.bankAccountHolder, "メグルム タロウ")
    }

    func testSaveSettingsPersistsDetailBeforeUpdatingPublicSummary() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000704")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PaymentSettingsMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseRESTClient(
            configuration: SupabaseConfiguration(
                projectURL: URL(string: "https://example.supabase.co")!,
                publishableKey: "anon-key",
                accessToken: "user-token"
            ),
            session: session
        )
        let persistence = SupabasePaymentSettingsPersistence(client: client)
        var requestPaths: [String] = []

        PaymentSettingsMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw PaymentSettingsMockError.missingURL
            }
            requestPaths.append(url.path)

            if request.httpMethod == "POST", url.path == "/rest/v1/user_payment_settings" {
                let payloads = try Self.jsonPayloads(from: request)
                XCTAssertEqual(payloads.first?["payment_methods"] as? [String], ["bank_transfer", "other"])
                let data = Data("""
                [
                  {
                    "user_id": "\(userID.uuidString.lowercased())",
                    "payment_methods": ["bank_transfer", "other"],
                    "bank_name": "みずほ銀行",
                    "bank_branch_name": "渋谷支店",
                    "bank_account_type": "普通",
                    "bank_account_number": "1234567",
                    "bank_account_holder": "ヤマダ ハナコ",
                    "other_note": "メルペイ",
                    "created_at": null,
                    "updated_at": null
                  }
                ]
                """.utf8)
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            if request.httpMethod == "PATCH", url.path == "/rest/v1/users" {
                let data = Data("""
                [
                  {
                    "id": "\(userID.uuidString.lowercased())",
                    "handle": "michi",
                    "display_name": "みち",
                    "avatar_url": null,
                    "gender": "female",
                    "primary_area": "東京都",
                    "age": 27,
                    "payment_methods": ["bank_transfer", "other"],
                    "payment_note": "メルペイ",
                    "account_status": "active"
                  }
                ]
                """.utf8)
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            throw PaymentSettingsMockError.unexpectedRequest(url.path)
        }
        defer {
            PaymentSettingsMockURLProtocol.requestHandler = nil
        }

        let saved = try await persistence.saveSettings(
            UserPaymentSettings(
                userID: userID,
                methods: [.other, .bankTransfer],
                bankName: "みずほ銀行",
                bankBranchName: "渋谷支店",
                bankAccountType: "普通",
                bankAccountNumber: "1234567",
                bankAccountHolder: "ヤマダ ハナコ",
                otherNote: "メルペイ"
            ),
            userID: userID
        )

        XCTAssertEqual(requestPaths, ["/rest/v1/user_payment_settings", "/rest/v1/users"])
        XCTAssertEqual(saved.profile.paymentMethods, [.bankTransfer, .other])
        XCTAssertEqual(saved.profile.paymentNote, "メルペイ")
        XCTAssertEqual(saved.settings.methods, [.bankTransfer, .other])
        XCTAssertEqual(saved.settings.bankName, "みずほ銀行")
        XCTAssertEqual(saved.settings.bankBranchName, "渋谷支店")
        XCTAssertEqual(saved.settings.bankAccountType, "普通")
        XCTAssertEqual(saved.settings.bankAccountNumber, "1234567")
        XCTAssertEqual(saved.settings.bankAccountHolder, "ヤマダ ハナコ")
        XCTAssertEqual(saved.settings.otherNote, "メルペイ")
    }

    func testSaveThenLoadSettingsKeepsMethodsInDetailStorage() async throws {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000706")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PaymentSettingsMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseRESTClient(
            configuration: SupabaseConfiguration(
                projectURL: URL(string: "https://example.supabase.co")!,
                publishableKey: "anon-key",
                accessToken: "user-token"
            ),
            session: session
        )
        let persistence = SupabasePaymentSettingsPersistence(client: client)
        var storedMethods: [String] = []
        var requestPaths: [String] = []

        PaymentSettingsMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw PaymentSettingsMockError.missingURL
            }
            requestPaths.append(url.path)

            if request.httpMethod == "POST", url.path == "/rest/v1/user_payment_settings" {
                let payloads = try Self.jsonPayloads(from: request)
                storedMethods = payloads.first?["payment_methods"] as? [String] ?? []
                let data = Self.detailRowData(
                    userID: userID,
                    methods: storedMethods,
                    otherNote: "メルペイ"
                )
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            if request.httpMethod == "PATCH", url.path == "/rest/v1/users" {
                let data = Data("""
                [
                  {
                    "id": "\(userID.uuidString.lowercased())",
                    "handle": "michi",
                    "display_name": "みち",
                    "avatar_url": null,
                    "gender": "female",
                    "primary_area": "東京都",
                    "age": 27,
                    "payment_methods": ["paypay", "other"],
                    "payment_note": "メルペイ",
                    "account_status": "active"
                  }
                ]
                """.utf8)
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            if request.httpMethod == "GET", url.path == "/rest/v1/user_payment_settings" {
                let data = Self.detailRowData(
                    userID: userID,
                    methods: storedMethods,
                    otherNote: "メルペイ"
                )
                return (PaymentSettingsMockURLProtocol.response(for: url, statusCode: 200), data)
            }

            throw PaymentSettingsMockError.unexpectedRequest(url.path)
        }
        defer {
            PaymentSettingsMockURLProtocol.requestHandler = nil
        }

        _ = try await persistence.saveSettings(
            UserPaymentSettings(
                userID: userID,
                methods: [.other, .paypay],
                otherNote: "メルペイ"
            ),
            userID: userID
        )
        let loaded = try await persistence.loadSettings(userID: userID)

        XCTAssertEqual(requestPaths, ["/rest/v1/user_payment_settings", "/rest/v1/users", "/rest/v1/user_payment_settings"])
        XCTAssertEqual(storedMethods, ["paypay", "other"])
        XCTAssertEqual(loaded?.methods, [.paypay, .other])
        XCTAssertEqual(loaded?.otherNote, "メルペイ")
    }

    private static func jsonPayloads(from request: URLRequest) throws -> [[String: Any]] {
        let body = try requestBody(from: request)
        guard let payloads = try JSONSerialization.jsonObject(with: body) as? [[String: Any]] else {
            throw PaymentSettingsMockError.invalidBody
        }
        return payloads
    }

    private static func requestBody(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            throw PaymentSettingsMockError.missingBody
        }

        stream.open()
        defer {
            stream.close()
        }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 {
                throw PaymentSettingsMockError.invalidBody
            }
            if count == 0 {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }

    private static func detailRowData(
        userID: UUID,
        methods: [String],
        otherNote: String?
    ) -> Data {
        let methodsJSON = methods.map { #""\#($0)""# }.joined(separator: ", ")
        let otherNoteJSON = otherNote.map { #""\#($0)""# } ?? "null"
        return Data("""
        [
          {
            "user_id": "\(userID.uuidString.lowercased())",
            "payment_methods": [\(methodsJSON)],
            "bank_name": null,
            "bank_branch_name": null,
            "bank_account_type": null,
            "bank_account_number": null,
            "bank_account_holder": null,
            "other_note": \(otherNoteJSON),
            "created_at": null,
            "updated_at": null
          }
        ]
        """.utf8)
    }
}

private enum PaymentSettingsMockError: Error {
    case missingURL
    case missingBody
    case invalidBody
    case unexpectedRequest(String)
}

private final class PaymentSettingsMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: PaymentSettingsMockError.unexpectedRequest("missing handler"))
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
