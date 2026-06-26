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

    func testSaveSettingsKeepsSummaryResultWhenDetailUpsertFails() async throws {
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

        XCTAssertEqual(requestPaths, ["/rest/v1/users", "/rest/v1/user_payment_settings"])
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
}

private enum PaymentSettingsMockError: Error {
    case missingURL
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
