@testable import MegrumApp
import MegrumCore
import XCTest

final class MegrumAppInitialSnapshotStateTests: XCTestCase {
    func testSnapshotStateKeepsVisibleViewedIDsAndLikedGroomIDs() {
        let visibleViewedID = UUID(uuidString: "00000000-0000-0000-0000-000000001001")!
        let likedID = UUID(uuidString: "00000000-0000-0000-0000-000000001002")!
        let staleViewedID = UUID(uuidString: "00000000-0000-0000-0000-000000001003")!
        let viewer = UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000001004")!,
            handle: "megrum",
            displayName: "めぐるむ"
        )
        let snapshot = MegrumAppSnapshot(
            viewer: viewer,
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [
                makePost(id: visibleViewedID, liked: false),
                makePost(id: likedID, liked: true)
            ],
            threads: [],
            subscriptionState: .free
        )

        let state = MegrumAppInitialSnapshotState(
            snapshot: snapshot,
            previousViewedGroomIDs: [visibleViewedID, staleViewedID]
        )

        XCTAssertEqual(state.viewer, viewer)
        XCTAssertEqual(state.grooms.map(\.id), [visibleViewedID, likedID])
        XCTAssertEqual(state.groomMapPosts.map(\.id), [visibleViewedID, likedID])
        XCTAssertEqual(state.viewedGroomIDs, [visibleViewedID])
        XCTAssertEqual(state.likedGroomIDs, [likedID])
        XCTAssertEqual(state.subscriptionState, .free)
    }

    private func makePost(id: UUID, liked: Bool) -> GroomPost {
        GroomPost(
            id: id,
            authorID: UUID(uuidString: "00000000-0000-0000-0000-000000001099")!,
            imageURL: URL(string: "https://example.com/groom-\(id.uuidString).jpg")!,
            latitude: 35.0,
            longitude: 139.0,
            liked: liked
        )
    }
}
