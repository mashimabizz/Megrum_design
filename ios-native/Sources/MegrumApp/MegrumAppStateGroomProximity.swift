import Foundation
import MegrumCore

extension MegrumAppState {
    /// FB(iter1226.390): 現在地1km圏内で自分の推しに一致した新規グルームを検出し、
    /// 遭遇記録（プレミアム圏外閲覧用）＋設定に合致すればローカル通知（iOS標準バナー）を出す。
    public func evaluateGroomProximity(latitude: Double, longitude: Double) async {
        guard let viewerID = viewer?.id, !groomMapPosts.isEmpty else { return }

        let current = MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
        let selections = userOshiSelections
        let oshiGroupIDs = Set(selections.compactMap(\.groupID))
        let oshiCharacterIDs = Set(selections.compactMap(\.characterID))
        guard !oshiGroupIDs.isEmpty || !oshiCharacterIDs.isEmpty else { return }

        var characterToGroup: [UUID: UUID] = [:]
        for selection in selections {
            if let characterID = selection.characterID, let groupID = selection.groupID {
                characterToGroup[characterID] = groupID
            }
        }

        let hits = GroomProximityEvaluator.newlyInRange(
            grooms: groomMapPosts,
            current: current,
            viewerID: viewerID,
            oshiGroupIDs: oshiGroupIDs,
            oshiCharacterIDs: oshiCharacterIDs,
            characterToGroup: characterToGroup
        )
        .filter { !processedProximityGroomIDs.contains($0.groom.id) }

        guard !hits.isEmpty else { return }

        let ids = hits.map(\.groom.id)
        processedProximityGroomIDs.formUnion(ids)
        markGroomsEncounteredInRange(ids)
        try? await repository.recordGroomEncounters(groomPostIDs: ids)

        // 通知はマスタON＋プッシュ許可＋推しごと設定に合致した時だけ。遭遇記録は設定に関わらず行う。
        guard pushNotificationsEnabled, groomOshiPushNotificationsEnabled else { return }
        if !hasLoadedGroomNotifyPrefs {
            await loadGroomNotifyPrefs()
        }
        for hit in hits where GroomProximityEvaluator.shouldNotify(hit: hit, prefs: groomNotifyPrefsByGroupID) {
            let body: String
            if let series = hit.groom.seriesName?.nilIfBlank {
                body = "\(series) のグルームが1km以内にあります"
            } else {
                body = "推しのグルームが1km以内にあります"
            }
            GroomLocalNotificationScheduler.schedule(
                for: hit.groom,
                title: "推しの近くにグルーム",
                body: body
            )
        }
    }

    /// FB(iter1226.390): プッシュのディープリンクから単一グルームを取得する。
    public func loadGroomPost(id: UUID) async -> GroomPost? {
        try? await repository.loadGroomPost(id: id)
    }

    /// iter1226.427：ビューア表示中のグルームを単発で取り直し、各キャッシュへ反映する。
    /// 他ユーザーからのいいねが自分のグルームの表示数に反映されない問題の対応。
    public func refreshGroomPostSnapshot(_ postID: UUID) async {
        guard let fresh = try? await repository.loadGroomPost(id: postID) else {
            return
        }
        // 既存位置を保った差し替え（存在しない配列には触れない）。
        grooms = grooms.map { $0.id == postID ? fresh : $0 }
        groomMapPosts = groomMapPosts.map { $0.id == postID ? fresh : $0 }
        encounteredGrooms = encounteredGrooms.map { $0.id == postID ? fresh : $0 }
        syncLikedGroomIDs(with: [fresh])
    }

    /// FB(iter1226.392): 出会った(遭遇済み)グルームを取得（ホーム列で圏外でも表示）。
    public func loadEncounteredGrooms(latitude: Double?, longitude: Double?) async {
        guard viewer != nil else { return }
        if let grooms = try? await repository.loadEncounteredGrooms(latitude: latitude, longitude: longitude) {
            encounteredGrooms = grooms
        }
    }

    /// ローカルの遭遇フラグを立てて、以降の再評価と圏外ゲート判定へ即反映する。
    func markGroomsEncounteredInRange(_ ids: [UUID]) {
        let idSet = Set(ids)
        groomMapPosts = groomMapPosts.map { groom in
            guard idSet.contains(groom.id) else { return groom }
            var updated = groom
            updated.encounteredInRange = true
            return updated
        }
    }
}
