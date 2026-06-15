@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseUserProfilePersistenceModelsTests: XCTestCase {
    func testUserRowSelectsCurrentPaymentAndAgeColumns() {
        XCTAssertEqual(
            UserRow.select,
            "id,handle,display_name,avatar_url,gender,primary_area,age,payment_methods,payment_note,account_status"
        )
        XCTAssertEqual(
            UserRow.legacySelect,
            "id,handle,display_name,avatar_url,gender,primary_area,account_status"
        )
    }

    func testOwnProfilePayloadOmitsAvatarURLWhenUnchanged() throws {
        let payload = UserOwnProfileUpdatePayload(
            handle: "michi",
            displayName: "みち",
            avatarUrl: nil,
            shouldEncodeAvatarUrl: false,
            gender: .female,
            primaryArea: "大阪府",
            paymentMethods: [.paypay]
        )

        let object = try encodedJSONObject(payload)

        XCTAssertEqual(object["handle"] as? String, "michi")
        XCTAssertNil(object["avatarUrl"])
    }

    func testOwnProfilePayloadEncodesNullAvatarURLWhenCleared() throws {
        let payload = UserOwnProfileUpdatePayload(
            handle: "michi",
            displayName: "みち",
            avatarUrl: nil,
            shouldEncodeAvatarUrl: true,
            gender: nil,
            primaryArea: nil,
            paymentMethods: []
        )

        let object = try encodedJSONObject(payload)

        XCTAssertTrue(object["avatarUrl"] is NSNull)
    }

    func testUserRowBuildsProfileFallbacks() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000321")!
        let row = UserRow(
            id: userID,
            handle: "michi",
            displayName: nil,
            avatarUrl: nil,
            gender: nil,
            primaryArea: "東京都",
            age: 24,
            paymentMethods: nil,
            paymentNote: nil,
            accountStatus: "unknown"
        )

        XCTAssertEqual(row.profile.id, userID)
        XCTAssertEqual(row.profile.handle, "michi")
        XCTAssertEqual(row.profile.displayName, "michi")
        XCTAssertEqual(row.profile.prefecture, "東京都")
        XCTAssertEqual(row.profile.age, 24)
        XCTAssertEqual(row.profile.paymentMethods, [])
        XCTAssertEqual(row.profile.accountStatus, .active)
    }

    private func encodedJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
