import Foundation
import MegrumCore

/// アプリ全体スナップショットの端末キャッシュ（iter1226.464）。
///
/// オフライン状態でアプリを開いても、取引チャットやめぐりメッセージの「一覧」を
/// 表示できるようにするための保存機構。ログインセッション自体は Keychain から
/// 復元されるため（`KeychainAuthSessionStore`）認証は通るが、起動時のスナップショット
/// 取得（`loadInitialSnapshot()`）はネットワークに依存し、オフラインだと失敗する。
/// その結果 `viewer` が nil のままになり、`viewer` を前提とする一覧（例：
/// `meguriMessageThreads`）がすべて空になってしまう。
///
/// そこで、オンライン時に取得した最新スナップショットと相手プロフィール辞書を
/// 認証ユーザーID単位で丸ごと保存し、次回オフライン起動時に即復元する。
/// テキストのやりとり本体は `MeguriMessageLocalStore` / `TradeMessageLocalStore`
/// が別途保持する。
enum MegrumOfflineSnapshotStore {
    /// 復元に必要な最小データ束。スナップショット本体に加えて、一覧の表示名・
    /// アバターに使う相手プロフィール辞書も持たせる（ネットワーク無しでも名前が出るように）。
    struct Payload: Codable, Sendable {
        var snapshot: MegrumAppSnapshot
        var publicProfiles: [UUID: PublicUserProfile]
        var meguriProfiles: [UUID: MeguriProfile]
    }

    private static func fileURL(for userID: UUID) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MegrumOfflineSnapshot", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("snapshot-\(userID.uuidString.lowercased()).json")
    }

    static func load(userID: UUID) -> Payload? {
        guard let url = try? fileURL(for: userID),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data)
    }

    static func save(_ payload: Payload, userID: UUID) {
        guard let url = try? fileURL(for: userID) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else {
            return
        }
        #if os(iOS)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try? data.write(to: url, options: [.atomic])
        #endif
    }

    static func clear(userID: UUID) {
        guard let url = try? fileURL(for: userID) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }
}
