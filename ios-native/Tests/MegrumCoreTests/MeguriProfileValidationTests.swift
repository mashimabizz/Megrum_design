import MegrumCore
import XCTest

final class MeguriProfileValidationTests: XCTestCase {
    func testNormalizesDisplayNameAndAllowsInitialSave() throws {
        let input = try MeguriProfileValidation.validate(
            displayName: " めぐり名 ",
            avatarID: "avatar_2",
            existingProfile: nil,
            now: Date(timeIntervalSince1970: 2_000)
        )

        XCTAssertEqual(input.displayName, "めぐり名")
        XCTAssertEqual(input.avatarID, "avatar_2")
    }

    func testRejectsBlankAndLongDisplayName() {
        XCTAssertThrowsError(
            try MeguriProfileValidation.validate(
                displayName: "   ",
                avatarID: "avatar_1",
                existingProfile: nil
            )
        ) { error in
            XCTAssertEqual(error as? MeguriProfileValidationError, .invalidDisplayName)
        }

        XCTAssertThrowsError(
            try MeguriProfileValidation.validate(
                displayName: String(repeating: "め", count: 25),
                avatarID: "avatar_1",
                existingProfile: nil
            )
        ) { error in
            XCTAssertEqual(error as? MeguriProfileValidationError, .invalidDisplayName)
        }
    }

    func testLocksChangedProfileForOneMonth() {
        let lastChangedAt = Date(timeIntervalSince1970: 2_000)
        let existing = MeguriProfile(
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "めぐり名",
            avatarID: "avatar_1",
            lastChangedAt: lastChangedAt
        )

        XCTAssertNoThrow(
            try MeguriProfileValidation.validate(
                displayName: "めぐり名",
                avatarID: "avatar_1",
                existingProfile: existing,
                now: lastChangedAt.addingTimeInterval(60 * 60 * 24)
            )
        )

        XCTAssertThrowsError(
            try MeguriProfileValidation.validate(
                displayName: "新しい名",
                avatarID: "avatar_1",
                existingProfile: existing,
                now: lastChangedAt.addingTimeInterval(60 * 60 * 24)
            )
        ) { error in
            guard case .lockedUntil? = error as? MeguriProfileValidationError else {
                return XCTFail("Expected lockedUntil")
            }
        }
    }
}
