@testable import MegrumApp
import MegrumCore
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
