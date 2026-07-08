import Foundation
import MegrumCore
#if os(iOS)
import UserNotifications
import UIKit
#endif

/// FB(iter1226.390): 自分の現在地1km圏内で自分の推しに一致した「新規」グルームを検出する。
/// 検出したものは遭遇(encounter)として記録し（プレミアムの圏外閲覧に使う）、
/// 通知設定に合致すればローカル通知（iOS標準のバナー）を出す。
enum GroomProximityEvaluator {
    /// リアルタイム圏内判定の半径（1km）。
    static let radiusMeters: Double = 1_000

    struct Hit: Equatable {
        let groom: GroomPost
        /// 解決したグループID（設定・通知判定に使う）。
        let resolvedGroupID: UUID?
    }

    /// まだ遭遇していない、1km圏内 かつ 自分の推し一致グルームを返す。
    static func newlyInRange(
        grooms: [GroomPost],
        current: MegrumLocationCoordinate,
        viewerID: UUID?,
        oshiGroupIDs: Set<UUID>,
        oshiCharacterIDs: Set<UUID>,
        characterToGroup: [UUID: UUID]
    ) -> [Hit] {
        grooms.compactMap { groom in
            guard groom.authorID != viewerID else { return nil }
            guard !groom.encounteredInRange else { return nil }

            let resolvedGroup = groom.groupID ?? groom.characterID.flatMap { characterToGroup[$0] }
            let matchesGroup = resolvedGroup.map { oshiGroupIDs.contains($0) } ?? false
            let matchesMember = groom.characterID.map { oshiCharacterIDs.contains($0) } ?? false
            guard matchesGroup || matchesMember else { return nil }

            guard let distance = MeguriAccessPolicy.distanceMeters(from: current, to: groom),
                  distance <= radiusMeters
            else {
                return nil
            }
            return Hit(groom: groom, resolvedGroupID: resolvedGroup)
        }
    }

    /// 通知設定（グループ有効・メンバー個別選択）に照らして通知対象か判定する。
    static func shouldNotify(hit: Hit, prefs: [UUID: GroomNotifyPref]) -> Bool {
        guard let groupID = hit.resolvedGroupID else {
            // グループ未解決でメンバー一致のみの場合は既定で通知する。
            return true
        }
        let pref = prefs[groupID] ?? GroomNotifyPref(groupID: groupID)
        return pref.notifies(characterID: hit.groom.characterID)
    }
}

/// iOS標準のローカル通知（フォアグラウンドでは画面上部のバナー）でグルーム接近を知らせる。
enum GroomLocalNotificationScheduler {
    static func schedule(for groom: GroomPost, title: String, body: String) {
        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "linkPath": "/grooms/\(groom.id.uuidString.lowercased())",
            "kind": "groom_posted"
        ]
        let request = UNNotificationRequest(
            identifier: "groom-proximity-\(groom.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
        #endif
    }
}
