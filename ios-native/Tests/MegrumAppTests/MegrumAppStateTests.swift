import MegrumApp
import XCTest

@MainActor
final class MegrumAppStateTests: XCTestCase {
    func testPreviewStateLoadsInitialSnapshot() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
        XCTAssertFalse(state.wishes.isEmpty)
        XCTAssertFalse(state.proposals.isEmpty)
        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertFalse(state.threads.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testFactoryFallsBackToPreviewWithoutSupabaseConfig() async {
        let state = MegrumAppStateFactory.make(environment: [:], infoDictionary: [:])

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }
}
