@testable import MegrumApp
import MegrumCore
import XCTest

final class PublicUserProfileScreenTests: XCTestCase {
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
