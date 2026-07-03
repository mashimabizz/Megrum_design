import Foundation

/// めぐりメッセージ一覧からローカルに非表示（削除）にしたスレッドの記録。
/// スレッドIDごとに非表示にした時刻を端末に保存し、その時刻より新しい
/// メッセージが届いたスレッドは一覧へ自動的に再表示する（LINE等の削除に
/// 近い体験）。サーバー側のメッセージ自体は削除しない。
public enum MeguriHiddenThreadStore {
    static func storageKey(viewerID: UUID) -> String {
        "megrum.meguri.hiddenThreads.\(viewerID.uuidString.lowercased())"
    }

    public static func load(viewerID: UUID, defaults: UserDefaults = .standard) -> [String: Date] {
        let raw = defaults.dictionary(forKey: storageKey(viewerID: viewerID)) ?? [:]
        return raw.compactMapValues { $0 as? Date }
    }

    public static func save(
        _ entries: [String: Date],
        viewerID: UUID,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(entries, forKey: storageKey(viewerID: viewerID))
    }

    /// 非表示にした時刻以降に新着がないスレッドだけを隠す。
    public static func isHidden(lastMessageAt: Date, hiddenAt: Date?) -> Bool {
        guard let hiddenAt else {
            return false
        }
        return lastMessageAt <= hiddenAt
    }
}
