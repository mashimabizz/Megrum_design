@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabasePublicProfilePersistenceTests: XCTestCase {
    func testProfileEnrichmentAddsOshiTagsWithoutChangingProfileSummary() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000001001")!
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000001002")!
        let characterID = UUID(uuidString: "00000000-0000-0000-0000-000000001003")!
        let profile = PublicUserProfile(
            profile: UserProfile(
                id: userID,
                handle: "mii",
                displayName: "みい",
                prefecture: "大阪府",
                accountStatus: .active
            ),
            averageStars: 4.7,
            evaluationCount: 3,
            completedTradeCount: 12
        )
        let selection = UserOshiSelection(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001004")!,
            userID: userID,
            groupID: groupID,
            characterID: characterID,
            kind: .specific,
            priority: 1,
            groupName: "TWICE",
            characterName: "モモ"
        )

        let enriched = SupabasePublicProfilePersistence.profile(
            profile,
            withOshiSelections: [selection]
        )

        XCTAssertEqual(enriched.profile, profile.profile)
        XCTAssertEqual(enriched.averageStars, 4.7)
        XCTAssertEqual(enriched.evaluationCount, 3)
        XCTAssertEqual(enriched.completedTradeCount, 12)
        XCTAssertEqual(enriched.oshiTags.map(\.title), ["TWICE", "モモ"])
        XCTAssertEqual(enriched.oshiTags[0].colorKey, enriched.oshiTags[1].colorKey)
    }

    func testProfileEnrichmentReplacesExistingTagsWithCurrentSelections() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000001011")!
        let profile = PublicUserProfile(
            profile: UserProfile(id: userID, handle: "mii", displayName: "みい"),
            oshiTags: [PublicOshiTag(title: "古い推し")]
        )

        let enriched = SupabasePublicProfilePersistence.profile(
            profile,
            withOshiSelections: []
        )

        XCTAssertTrue(enriched.oshiTags.isEmpty)
    }
}
