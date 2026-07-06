import Foundation

/// チャットルーム（掲示板スレッド）を開いた時刻をローカルに記録する。
/// 通知一覧で「すでに見たルームの通知」を自動既読にする判定に使う。
enum BoardThreadVisitStore {
    private static let maxEntries = 200

    private static func key(viewerID: UUID) -> String {
        "megrum.boardThreadVisits.\(viewerID.uuidString)"
    }

    static func visitedAt(
        threadID: UUID,
        viewerID: UUID,
        defaults: UserDefaults = .standard
    ) -> Date? {
        let stored = defaults.dictionary(forKey: key(viewerID: viewerID)) as? [String: Double] ?? [:]
        return stored[threadID.uuidString].map(Date.init(timeIntervalSince1970:))
    }

    static func recordVisit(
        threadID: UUID,
        viewerID: UUID,
        at date: Date = .now,
        defaults: UserDefaults = .standard
    ) {
        var stored = defaults.dictionary(forKey: key(viewerID: viewerID)) as? [String: Double] ?? [:]
        stored[threadID.uuidString] = date.timeIntervalSince1970
        if stored.count > maxEntries {
            // 古い訪問から間引く（判定は「通知より後に見たか」なので古い記録は不要）。
            let sorted = stored.sorted { $0.value > $1.value }.prefix(maxEntries)
            stored = Dictionary(uniqueKeysWithValues: Array(sorted))
        }
        defaults.set(stored, forKey: key(viewerID: viewerID))
    }
}
