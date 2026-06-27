@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabaseAccountProfilePersistenceTests: XCTestCase {
    private let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000901")!

    func testViewerQueryItemsFilterCurrentUser() {
        let items = SupabaseAccountProfilePersistence.viewerQueryItems(userID: userID)

        XCTAssertEqual(items.map(\.name), ["id", "limit"])
        XCTAssertEqual(items.map(\.value), ["eq.00000000-0000-0000-0000-000000000901", "1"])
    }

    func testFallbackViewerProfileKeepsOnboardingStatus() {
        let profile = SupabaseAccountProfilePersistence.fallbackViewerProfile(userID: userID)

        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "megrum")
        XCTAssertEqual(profile.displayName, "Megrum")
        XCTAssertNil(profile.prefecture)
        XCTAssertEqual(profile.accountStatus, .onboarding)
    }

    func testResolvedAvatarUpdateOmitsAvatarWhenUnchanged() {
        let input = OwnProfileUpdateInput(
            handle: "michi",
            displayName: "みち",
            avatarURL: nil,
            clearsAvatar: false
        )

        let update = SupabaseAccountProfilePersistence.resolvedAvatarUpdate(
            input: input,
            uploadedAvatarURL: nil
        )

        XCTAssertNil(update.url)
        XCTAssertFalse(update.shouldEncode)
    }

    func testResolvedAvatarUpdatePrefersUploadedAvatarURL() throws {
        let currentURL = try XCTUnwrap(URL(string: "https://example.com/current.jpg"))
        let uploadedURL = try XCTUnwrap(URL(string: "https://example.com/uploaded.jpg"))
        let input = OwnProfileUpdateInput(
            handle: "michi",
            displayName: "みち",
            avatarURL: currentURL,
            avatarUpload: GoodsPhotoUpload(data: Data([1, 2, 3]), contentType: "image/jpeg"),
            clearsAvatar: false
        )

        let update = SupabaseAccountProfilePersistence.resolvedAvatarUpdate(
            input: input,
            uploadedAvatarURL: uploadedURL
        )

        XCTAssertEqual(update.url, uploadedURL)
        XCTAssertTrue(update.shouldEncode)
    }

    func testResolvedAvatarUpdateEncodesNilWhenCleared() throws {
        let currentURL = try XCTUnwrap(URL(string: "https://example.com/current.jpg"))
        let input = OwnProfileUpdateInput(
            handle: "michi",
            displayName: "みち",
            avatarURL: currentURL,
            clearsAvatar: true
        )

        let update = SupabaseAccountProfilePersistence.resolvedAvatarUpdate(
            input: input,
            uploadedAvatarURL: nil
        )

        XCTAssertNil(update.url)
        XCTAssertTrue(update.shouldEncode)
    }

    func testOwnProfileFallbackReflectsSavedFields() throws {
        let avatarURL = try XCTUnwrap(URL(string: "https://example.com/avatar.jpg"))
        let input = OwnProfileUpdateInput(
            handle: "michi",
            displayName: "みち",
            gender: .female,
            prefecture: "大阪府",
            paymentMethods: [.paypay],
            avatarURL: avatarURL
        )

        let profile = SupabaseAccountProfilePersistence.fallbackOwnProfile(
            input: input,
            userID: userID,
            avatarURL: avatarURL
        )

        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "michi")
        XCTAssertEqual(profile.displayName, "みち")
        XCTAssertEqual(profile.avatarURL, avatarURL)
        XCTAssertEqual(profile.gender, .female)
        XCTAssertEqual(profile.prefecture, "大阪府")
        XCTAssertEqual(profile.paymentMethods, [.paypay])
        XCTAssertEqual(profile.accountStatus, .active)
    }

    func testAccountSetupPayloadAndFallbackActivateProfile() {
        let birthDate = ProfileBirthDateCodec.date(from: "2000-02-03")
        let input = AccountSetupInput(
            handle: "michirion",
            displayName: "みちりおん",
            gender: .female,
            prefecture: "東京都",
            birthDate: birthDate,
            oshiSelections: []
        )

        let payload = SupabaseAccountProfilePersistence.accountSetupUpdatePayload(from: input)
        let profile = SupabaseAccountProfilePersistence.fallbackAccountSetupProfile(
            input: input,
            userID: userID
        )

        XCTAssertEqual(payload.handle, "michirion")
        XCTAssertEqual(payload.displayName, "みちりおん")
        XCTAssertEqual(payload.gender, .female)
        XCTAssertEqual(payload.primaryArea, "東京都")
        XCTAssertEqual(payload.birthDate, "2000-02-03")
        XCTAssertEqual(payload.age, ProfileBirthDateCodec.age(from: birthDate))
        XCTAssertEqual(payload.accountStatus, AccountStatus.active.rawValue)
        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "michirion")
        XCTAssertEqual(profile.displayName, "みちりおん")
        XCTAssertEqual(profile.gender, .female)
        XCTAssertEqual(profile.prefecture, "東京都")
        XCTAssertEqual(ProfileBirthDateCodec.string(from: profile.birthDate), "2000-02-03")
        XCTAssertEqual(profile.age, ProfileBirthDateCodec.age(from: birthDate))
        XCTAssertEqual(profile.accountStatus, .active)
    }

    func testAccountSetupUpsertPayloadCarriesUserIDAndStatus() {
        let birthDate = ProfileBirthDateCodec.date(from: "2000-02-03")
        let input = AccountSetupInput(
            handle: "megrum_000000000901",
            displayName: "Megrumユーザー",
            gender: .female,
            prefecture: "東京都",
            birthDate: birthDate,
            oshiSelections: []
        )

        let payload = SupabaseAccountProfilePersistence.accountSetupUpsertPayload(
            from: input,
            userID: userID,
            accountStatus: .onboarding
        )

        XCTAssertEqual(payload.id, userID)
        XCTAssertEqual(payload.handle, "megrum_000000000901")
        XCTAssertEqual(payload.displayName, "Megrumユーザー")
        XCTAssertEqual(payload.gender, .female)
        XCTAssertEqual(payload.primaryArea, "東京都")
        XCTAssertEqual(payload.birthDate, "2000-02-03")
        XCTAssertEqual(payload.age, ProfileBirthDateCodec.age(from: birthDate))
        XCTAssertEqual(payload.accountStatus, AccountStatus.onboarding.rawValue)
    }

    func testAccountSetupLegacyPayloadOmitsBirthDateAndAge() throws {
        let birthDate = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2000-02-03"))
        let input = AccountSetupInput(
            handle: "michirion",
            displayName: "みちりおん",
            gender: .female,
            prefecture: "東京都",
            birthDate: birthDate,
            oshiSelections: []
        )

        let payload = SupabaseAccountProfilePersistence.accountSetupLegacyUpsertPayload(
            from: input,
            userID: userID,
            accountStatus: .active
        )
        let data = try JSONEncoder.megrumSnakeCase.encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual((json["id"] as? String)?.lowercased(), userID.uuidString.lowercased())
        XCTAssertEqual(json["handle"] as? String, "michirion")
        XCTAssertEqual(json["display_name"] as? String, "みちりおん")
        XCTAssertEqual(json["gender"] as? String, "female")
        XCTAssertEqual(json["primary_area"] as? String, "東京都")
        XCTAssertEqual(json["account_status"] as? String, "active")
        XCTAssertNil(json["birth_date"])
        XCTAssertNil(json["age"])
    }

    func testAccountSetupProfileSelectAvoidsRestrictedColumns() {
        let select = SupabaseAccountProfilePersistence.accountSetupProfileSelect

        XCTAssertTrue(select.contains("id"))
        XCTAssertTrue(select.contains("handle"))
        XCTAssertFalse(select.contains("birth_date"))
        XCTAssertFalse(select.contains("age"))
        XCTAssertFalse(select.contains("payment_methods"))
        XCTAssertFalse(select.contains("payment_note"))
    }

    func testMergedAccountSetupProfileRestoresBirthDateAndAgeFromInput() {
        let birthDate = ProfileBirthDateCodec.date(from: "2000-02-03")
        let input = AccountSetupInput(
            handle: "michirion",
            displayName: "みちりおん",
            gender: .female,
            prefecture: "東京都",
            birthDate: birthDate,
            oshiSelections: []
        )
        let storedProfile = UserProfile(
            id: userID,
            handle: "michirion",
            displayName: "みちりおん",
            gender: nil,
            prefecture: nil,
            accountStatus: .active
        )

        let profile = SupabaseAccountProfilePersistence.mergedAccountSetupProfile(
            storedProfile: storedProfile,
            input: input,
            userID: userID
        )

        XCTAssertEqual(profile.id, userID)
        XCTAssertEqual(profile.handle, "michirion")
        XCTAssertEqual(profile.displayName, "みちりおん")
        XCTAssertEqual(profile.gender, .female)
        XCTAssertEqual(profile.prefecture, "東京都")
        XCTAssertEqual(ProfileBirthDateCodec.string(from: profile.birthDate), "2000-02-03")
        XCTAssertEqual(profile.age, ProfileBirthDateCodec.age(from: birthDate))
        XCTAssertEqual(profile.accountStatus, .active)
    }

    func testCompleteAccountSetupActivatesProfileWhenOshiSaveFails() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AccountSetupMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseRESTClient(
            configuration: SupabaseConfiguration(
                projectURL: URL(string: "https://example.supabase.co")!,
                publishableKey: "anon-key",
                accessToken: "user-token"
            ),
            session: session
        )
        let persistence = SupabaseAccountProfilePersistence(
            client: client,
            oshiClient: SupabaseOshiClient(client: client),
            profilePhotoStorage: SupabaseProfilePhotoStorage(client: client),
            userID: userID
        )
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000911")!
        let birthDate = ProfileBirthDateCodec.date(from: "2000-02-03")
        let input = AccountSetupInput(
            handle: "michirion",
            displayName: "みちりおん",
            gender: .female,
            prefecture: "東京都",
            birthDate: birthDate,
            oshiSelections: [
                AccountSetupOshiInput(groupID: groupID, characterID: nil, kind: .box, priority: 1)
            ]
        )
        var requests: [(method: String, path: String)] = []

        AccountSetupMockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw AccountSetupMockError.missingURL
            }
            requests.append((request.httpMethod ?? "", url.path))

            if request.httpMethod == "POST", url.path == "/rest/v1/users" {
                let data = Data("""
                [
                  {
                    "id": "\(self.userID.uuidString.lowercased())",
                    "handle": "michirion",
                    "display_name": "みちりおん",
                    "avatar_url": null,
                    "gender": "female",
                    "primary_area": "東京都",
                    "account_status": "active"
                  }
                ]
                """.utf8)
                return (AccountSetupMockURLProtocol.response(for: url, statusCode: 201), data)
            }

            if request.httpMethod == "DELETE", url.path == "/rest/v1/user_oshi" {
                return (AccountSetupMockURLProtocol.response(for: url, statusCode: 204), Data())
            }

            if request.httpMethod == "POST", url.path == "/rest/v1/user_oshi" {
                return (
                    AccountSetupMockURLProtocol.response(for: url, statusCode: 500),
                    Data(#"{"message":"temporary oshi failure"}"#.utf8)
                )
            }

            throw AccountSetupMockError.unexpectedRequest(url.path)
        }
        defer {
            AccountSetupMockURLProtocol.requestHandler = nil
        }

        let profile = try await persistence.completeAccountSetup(input)

        XCTAssertEqual(profile.accountStatus, .active)
        XCTAssertEqual(ProfileBirthDateCodec.string(from: profile.birthDate), "2000-02-03")
        XCTAssertEqual(
            requests.map { "\($0.method) \($0.path)" },
            [
                "POST /rest/v1/users",
                "DELETE /rest/v1/user_oshi",
                "POST /rest/v1/user_oshi"
            ]
        )
    }

    func testAccountSetupSelectionsPreserveInputFields() {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000911")!
        let characterID = UUID(uuidString: "00000000-0000-0000-0000-000000000912")!
        let requestID = UUID(uuidString: "00000000-0000-0000-0000-000000000913")!
        let characterRequestID = UUID(uuidString: "00000000-0000-0000-0000-000000000914")!
        let input = AccountSetupInput(
            displayName: "みち",
            oshiSelections: [
                AccountSetupOshiInput(
                    groupID: groupID,
                    characterID: characterID,
                    kind: .specific,
                    priority: 2,
                    oshiRequestID: requestID,
                    characterRequestID: characterRequestID
                )
            ]
        )

        let selections = SupabaseAccountProfilePersistence.accountSetupSelections(
            from: input,
            userID: userID
        )

        XCTAssertEqual(selections.count, 1)
        XCTAssertEqual(selections[0].userID, userID)
        XCTAssertEqual(selections[0].groupID, groupID)
        XCTAssertEqual(selections[0].characterID, characterID)
        XCTAssertEqual(selections[0].kind, .specific)
        XCTAssertEqual(selections[0].priority, 2)
        XCTAssertEqual(selections[0].oshiRequestID, requestID)
        XCTAssertEqual(selections[0].characterRequestID, characterRequestID)
    }

    func testAccountDeletionPayloadUsesReasonRawValuesAndNormalizedMemo() {
        let payload = SupabaseAccountProfilePersistence.accountDeletionPayload(
            from: AccountDeletionRequestInput(
                reasons: [.notUsing, .privacyConcern, .notUsing],
                note: "  少し休みます  "
            )
        )

        XCTAssertEqual(payload.reasons, ["not_using", "privacy_concern"])
        XCTAssertEqual(payload.note, "少し休みます")
    }
}

private enum AccountSetupMockError: Error {
    case missingURL
    case unexpectedRequest(String)
}

private final class AccountSetupMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: AccountSetupMockError.unexpectedRequest("missing handler"))
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

private extension JSONEncoder {
    static var megrumSnakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
