import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("MegrumOfflineSnapshotStore")
struct MegrumOfflineSnapshotStoreTests {
    @Test("保存したスナップショットはユーザーごとに読み戻せる")
    func roundTrip() {
        let userID = UUID()
        let otherUserID = UUID()
        MegrumOfflineSnapshotStore.clear(userID: userID)
        MegrumOfflineSnapshotStore.clear(userID: otherUserID)

        let viewer = UserProfile(id: userID, handle: "viewer", displayName: "閲覧者")
        let snapshot = MegrumAppSnapshot(
            viewer: viewer,
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: [],
            subscriptionState: .free
        )
        let payload = MegrumOfflineSnapshotStore.Payload(
            snapshot: snapshot,
            publicProfiles: [:],
            meguriProfiles: [:]
        )

        MegrumOfflineSnapshotStore.save(payload, userID: userID)

        let loaded = MegrumOfflineSnapshotStore.load(userID: userID)
        #expect(loaded?.snapshot.viewer.id == userID)
        #expect(loaded?.snapshot.viewer.handle == "viewer")
        #expect(MegrumOfflineSnapshotStore.load(userID: otherUserID) == nil)

        MegrumOfflineSnapshotStore.clear(userID: userID)
        #expect(MegrumOfflineSnapshotStore.load(userID: userID) == nil)
    }
}
