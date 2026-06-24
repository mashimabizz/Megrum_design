@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseInitialSnapshotLoaderTests: XCTestCase {
    func testBoardScopeUsesNearbyWhenViewerHasNoPrefecture() {
        let viewer = makeViewer(prefecture: nil)

        XCTAssertEqual(SupabaseInitialSnapshotLoader.boardScope(for: viewer), .nearby3km)
    }

    func testBoardScopeUsesSamePrefectureWhenViewerHasPrefecture() {
        let viewer = makeViewer(prefecture: "大阪府")

        XCTAssertEqual(SupabaseInitialSnapshotLoader.boardScope(for: viewer), .samePrefecture)
    }

    func testBestEffortInitialSectionReturnsOperationValue() async {
        let value = await SupabaseInitialSnapshotLoader.bestEffortInitialSection(1) {
            2
        }

        XCTAssertEqual(value, 2)
    }

    func testBestEffortInitialSectionReturnsFallbackWhenOperationFails() async {
        let value = await SupabaseInitialSnapshotLoader.bestEffortInitialSection("fallback") {
            throw TestError.failed
        }

        XCTAssertEqual(value, "fallback")
    }

    func testDefaultGroomRadiusKeepsInitialSnapshotRadius() {
        XCTAssertEqual(SupabaseInitialSnapshotLoader.defaultGroomRadiusMeters, 1_000)
    }

    func testListingsAreRequiredForInitialSnapshot() {
        XCTAssertTrue(SupabaseInitialSnapshotLoader.requiresListingsForInitialSnapshot)
    }

    private func makeViewer(prefecture: String?) -> UserProfile {
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000981")!,
            handle: "michi",
            displayName: "みち",
            avatarURL: nil,
            gender: .female,
            prefecture: prefecture,
            age: 24,
            paymentMethods: [.paypay],
            accountStatus: .active
        )
    }

    private enum TestError: Error {
        case failed
    }
}
