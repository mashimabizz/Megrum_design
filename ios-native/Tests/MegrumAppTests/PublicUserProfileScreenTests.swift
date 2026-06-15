@testable import MegrumApp
import MegrumCore
import XCTest

final class PublicUserProfileScreenTests: XCTestCase {
    func testPublicOshiTagsKeepGroupAndMemberInSameColorGroup() {
        let groupID = UUID(uuidString: "10000000-0000-0000-0000-000000000101")!
        let characterID = UUID(uuidString: "10000000-0000-0000-0000-000000000102")!
        let selection = UserOshiSelection(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000103")!,
            userID: UUID(uuidString: "10000000-0000-0000-0000-000000000104")!,
            groupID: groupID,
            characterID: characterID,
            kind: .specific,
            priority: 1,
            groupName: "IVE",
            characterName: "ウォニョン"
        )

        let tags = PublicOshiTag.makeTags(from: [selection])

        XCTAssertEqual(tags.map(\.title), ["IVE", "ウォニョン"])
        XCTAssertEqual(tags[0].colorKey, tags[1].colorKey)
    }

    func testPublicOshiTagsDeduplicateRepeatedGroupRows() {
        let groupID = UUID(uuidString: "10000000-0000-0000-0000-000000000201")!
        let userID = UUID(uuidString: "10000000-0000-0000-0000-000000000202")!
        let selections = [
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000203")!,
                userID: userID,
                groupID: groupID,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000204")!,
                kind: .specific,
                priority: 1,
                groupName: "TWICE",
                characterName: "モモ"
            ),
            UserOshiSelection(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000205")!,
                userID: userID,
                groupID: groupID,
                characterID: UUID(uuidString: "10000000-0000-0000-0000-000000000206")!,
                kind: .specific,
                priority: 2,
                groupName: "TWICE",
                characterName: "サナ"
            )
        ]

        let tags = PublicOshiTag.makeTags(from: selections)

        XCTAssertEqual(tags.map(\.title), ["TWICE", "モモ", "サナ"])
        XCTAssertTrue(tags.allSatisfy { $0.colorKey == groupID.uuidString })
    }

    func testEvaluationListStateShowsLoadingForEmptyLoadingList() {
        let state = PublicProfileEvaluationListState(evaluations: [], isLoading: true)

        XCTAssertTrue(state.showsLoading)
        XCTAssertFalse(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 0)
    }

    func testEvaluationListStateShowsEmptyForLoadedEmptyList() {
        let state = PublicProfileEvaluationListState(evaluations: [], isLoading: false)

        XCTAssertFalse(state.showsLoading)
        XCTAssertTrue(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 0)
    }

    func testEvaluationListStateKeepsRowsVisibleWhileRefreshing() {
        let state = PublicProfileEvaluationListState(
            evaluations: [
                UserEvaluation(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                    raterID: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                    raterHandle: "michi1",
                    raterDisplayName: "みち",
                    stars: 5,
                    comment: "丁寧に交換できました"
                )
            ],
            isLoading: true
        )

        XCTAssertFalse(state.showsLoading)
        XCTAssertFalse(state.showsEmpty)
        XCTAssertEqual(state.evaluationCount, 1)
    }
}
