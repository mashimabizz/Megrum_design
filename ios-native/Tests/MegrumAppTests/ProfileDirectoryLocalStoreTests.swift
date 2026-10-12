import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("ProfileDirectoryLocalStore")
struct ProfileDirectoryLocalStoreTests {
    @Test("保存した相手プロフィール辞書はユーザーごとに読み戻せる")
    func roundTrip() {
        let userID = UUID()
        let otherUserID = UUID()
        ProfileDirectoryLocalStore.clear(userID: userID)
        ProfileDirectoryLocalStore.clear(userID: otherUserID)

        let partnerID = UUID()
        let publicProfile = PublicUserProfile(
            profile: UserProfile(id: partnerID, handle: "partner", displayName: "取引相手")
        )
        let meguriID = UUID()
        let meguriProfile = MeguriProfile(userID: meguriID, displayName: "めぐり相手")

        let payload = ProfileDirectoryLocalStore.Payload(
            publicProfiles: [partnerID: publicProfile],
            meguriProfiles: [meguriID: meguriProfile]
        )
        ProfileDirectoryLocalStore.save(payload, userID: userID)

        let loaded = ProfileDirectoryLocalStore.load(userID: userID)
        #expect(loaded?.publicProfiles[partnerID]?.profile.displayName == "取引相手")
        #expect(loaded?.meguriProfiles[meguriID]?.displayName == "めぐり相手")
        #expect(ProfileDirectoryLocalStore.load(userID: otherUserID) == nil)

        ProfileDirectoryLocalStore.clear(userID: userID)
        #expect(ProfileDirectoryLocalStore.load(userID: userID) == nil)
    }
}
