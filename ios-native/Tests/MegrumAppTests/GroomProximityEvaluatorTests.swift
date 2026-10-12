import Foundation
import MegrumCore
import Testing
@testable import MegrumApp

@Suite("GroomProximityEvaluator")
struct GroomProximityEvaluatorTests {
    private let viewerID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
    private let authorID = UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
    private let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    private let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
    private let current = MegrumLocationCoordinate(latitude: 35.0, longitude: 139.0)

    private func groom(
        latitude: Double,
        groupID: UUID?,
        characterID: UUID? = nil,
        encountered: Bool = false,
        author: UUID? = nil
    ) -> GroomPost {
        GroomPost(
            id: UUID(),
            authorID: author ?? authorID,
            imageURL: URL(string: "https://example.com/g.jpg")!,
            latitude: latitude,
            longitude: 139.0,
            groupID: groupID,
            characterID: characterID,
            encounteredInRange: encountered
        )
    }

    // 緯度 +0.005 ≈ 約550m（圏内）、+0.02 ≈ 約2.2km（圏外）。

    @Test("圏内・推しグループ一致・未遭遇のみ返す")
    func newlyInRangeBasic() {
        let inRange = groom(latitude: 35.005, groupID: groupID)
        let outOfRange = groom(latitude: 35.02, groupID: groupID)
        let otherOshi = groom(latitude: 35.005, groupID: UUID())
        let own = groom(latitude: 35.005, groupID: groupID, author: viewerID)
        let already = groom(latitude: 35.005, groupID: groupID, encountered: true)

        let hits = GroomProximityEvaluator.newlyInRange(
            grooms: [inRange, outOfRange, otherOshi, own, already],
            current: current,
            viewerID: viewerID,
            oshiGroupIDs: [groupID],
            oshiCharacterIDs: [],
            characterToGroup: [:]
        )
        #expect(hits.map(\.groom.id) == [inRange.id])
        #expect(hits.first?.resolvedGroupID == groupID)
    }

    @Test("group_id未設定でもcharacter→group解決で一致")
    func resolvesGroupFromCharacter() {
        let g = groom(latitude: 35.005, groupID: nil, characterID: memberID)
        let hits = GroomProximityEvaluator.newlyInRange(
            grooms: [g],
            current: current,
            viewerID: viewerID,
            oshiGroupIDs: [groupID],
            oshiCharacterIDs: [],
            characterToGroup: [memberID: groupID]
        )
        #expect(hits.count == 1)
        #expect(hits.first?.resolvedGroupID == groupID)
    }

    @Test("通知判定：全メンバーONは通知、メンバー選択は該当時のみ")
    func shouldNotifyByPref() {
        let hit = GroomProximityEvaluator.Hit(
            groom: groom(latitude: 35.005, groupID: groupID, characterID: memberID),
            resolvedGroupID: groupID
        )
        // 既定（pref未収載）＝通知
        #expect(GroomProximityEvaluator.shouldNotify(hit: hit, prefs: [:]))
        // グループ無効＝通知しない
        #expect(!GroomProximityEvaluator.shouldNotify(
            hit: hit,
            prefs: [groupID: GroomNotifyPref(groupID: groupID, enabled: false)]
        ))
        // 選択メンバーに含む＝通知
        #expect(GroomProximityEvaluator.shouldNotify(
            hit: hit,
            prefs: [groupID: GroomNotifyPref(groupID: groupID, notifyAllMembers: false, memberCharacterIDs: [memberID])]
        ))
        // 選択メンバーに含まない＝通知しない
        #expect(!GroomProximityEvaluator.shouldNotify(
            hit: hit,
            prefs: [groupID: GroomNotifyPref(groupID: groupID, notifyAllMembers: false, memberCharacterIDs: [UUID()])]
        ))
    }
}
